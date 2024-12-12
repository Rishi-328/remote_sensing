const express = require('express');
const bodyParser = require('body-parser');
// const twilio = require('twilio');
const dotenv = require('dotenv');
const cors = require('cors');
const ort = require('onnxruntime-node');
const fs = require('fs');
const path = require('path');
const { Buffer } = require('buffer');
const sharp = require('sharp');  // For image processing
const multer = require("multer");
const cv = require('@techstark/opencv-js');


// const upload = multer({ storage: multer.memoryStorage() });

// const modelPath = path.join(__dirname, 'modelSpec.onnx');
// Load environment variables from the .env file
dotenv.config();

const app = express();
const port = process.env.PORT || 5000;

// Twilio credentials from environment variables
// const accountSid = process.env.TWILIO_ACCOUNT_SID;
// const authToken = process.env.TWILIO_AUTH_TOKEN;
// const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

// const client = twilio(accountSid, authToken);

// Enable CORS for cross-origin requests
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));  // Adjust payload size limit for larger images





// Load ONNX model
const modelPath = path.join(__dirname, 'modelSpecNew.onnx'); // Path to ONNX model
let Cropsession;

const sarModelPath = path.join(__dirname, "sar2rgb2.onnx"); // Path to SAR colorization ONNX model
let sarSession;

const vitModelPath = path.join(__dirname,"vit.onnx");
let vitSession;

// Path to the flood detection ONNX model
const floodModelPath = path.join(__dirname, 'unetr.onnx');
let floodSession;

async function loadCropModel() {
  try {
    Cropsession = await ort.InferenceSession.create(modelPath);
    console.log('Crop model loaded successfully');
  } catch (error) {
    console.error('Error loading ONNX model:', error);
  }
}
loadCropModel();

async function loadSarModel() {
  try {
    sarSession = await ort.InferenceSession.create(sarModelPath);
    console.log("SAR colorization model loaded successfully");
  } catch (error) {
    console.error("Error loading SAR model:", error);
  }
}
loadSarModel();


async function loadVitModel() {
  try {
    vitSession = await ort.InferenceSession.create(vitModelPath);
    console.log("Crop classification with vit model loaded successfully");
  } catch (error) {
    console.error("Error loading vit model:", error);
  }
}
loadVitModel();

// Load flood detection model
async function loadFloodModel() {
  try {
    floodSession = await ort.InferenceSession.create(floodModelPath);
    console.log('Flood detection model loaded successfully');
  } catch (error) {
    console.error('Error loading flood detection model:', error);
  }
}
loadFloodModel();


async function preprocessImage(imageBuffer) {
  try {
    // Load the image and resize it to 224x224 pixels
    const { data, info } = await sharp(imageBuffer)
      .resize(224, 224)
      .raw()
      .toBuffer({ resolveWithObject: true });

    const { width, height, channels } = info;

    if (channels !== 3) {
      throw new Error('Image must have 3 channels (RGB)');
    }

    // Define normalization parameters (same as in PyTorch)
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    // Create a Float32Array to hold the normalized data
    const chwData = new Float32Array(width * height * channels);

    // Rearrange and normalize the data from HWC to CHW format
    for (let c = 0; c < channels; c++) {
      for (let h = 0; h < height; h++) {
        for (let w = 0; w < width; w++) {
          const hwcIndex = h * width * channels + w * channels + c; // Index in HWC format
          const chwIndex = c * width * height + h * width + w;      // Index in CHW format

          // Normalize the pixel value
          const value = data[hwcIndex] / 255.0; // Scale to [0, 1]
          chwData[chwIndex] = (value - mean[c]) / std[c]; // Apply normalization
        }
      }
    }

    // Create the tensor with the correct shape [1, 3, 224, 224]
    const tensor = new ort.Tensor('float32', chwData, [1, 3, height, width]);

    return tensor;
  } catch (error) {
    console.error('Error preprocessing image:', error);
    throw new Error('Image preprocessing failed');
  }
}


// Inference function
async function runModel(imageTensor) {
  try {
    const feeds = { [Cropsession.inputNames[0]]: imageTensor }; // Use actual input name
    const output = await Cropsession.run(feeds);
    const outputTensor = output[Cropsession.outputNames[0]];    // Use actual output name

    // Get the predicted class index
    const scores = outputTensor.data;
    const predictedIndex = scores.indexOf(Math.max(...scores));

    const crops = ['jute', 'maize', 'rice', 'sugarcane', 'wheat'];
    return crops[predictedIndex];
  } catch (error) {
    console.error('Error running model:', error);
    throw new Error('Model inference failed');
  }
}

async function runVITModel(imageTensor){
  try{
    const feeds = {[vitSession.inputNames[0]]:imageTensor};
    const output = await vitSession.run(feeds);
    const outputTensor = output[vitSession.outputNames[0]];
    const scores = outputTensor.data;
    const predictedIndex = scores.indexOf(Math.max(...scores));
    const crops = ['jute','maize','rice','sugarcane','wheat'];
    return crops[predictedIndex];
  }catch(error){
    console.log('Error running model:', error);
    throw new Error('VIT Model inference failed');
  }
}

async function preprocessSarImage(imageBuffer) {
  try {
    const { data, info } = await sharp(imageBuffer)
      .resize(256, 256) // Resize image to 256x256
      .raw() // Keep the image in its original format (no color space conversion)
      .toBuffer({ resolveWithObject: true });

    const { width, height, channels } = info;

    // Ensure the input is in the shape [1, 3, H, W]
    const chwData = new Float32Array(width * height * channels);
    const mean = [0.5, 0.5, 0.5]; // Pix2Pix normalization (mean and std are 0.5)
    const std = [0.5, 0.5, 0.5];

    for (let c = 0; c < channels; c++) {
      for (let h = 0; h < height; h++) {
        for (let w = 0; w < width; w++) {
          const hwcIndex = h * width * channels + w * channels + c; // Index in HWC format
          const chwIndex = c * width * height + h * width + w;      // Index in CHW format
          const value = data[hwcIndex] / 255.0; // Scale pixel to [0, 1]
          chwData[chwIndex] = (value - mean[c]) / std[c]; // Normalize
        }
      }
    }

    // Create a tensor in the shape [1, 3, 256, 256]
    const tensor = new ort.Tensor('float32', chwData, [1, 3, height, width]);
    return tensor;
  } catch (error) {
    console.error('Error preprocessing image:', error);
    throw new Error('Preprocessing failed');
  }
}

async function postprocessSarImage(outputTensor) {
  const [_, channels, height, width] = outputTensor.dims;
  const data = outputTensor.data; // Flattened output array

  const chwData = new Uint8Array(width * height * channels);

  for (let c = 0; c < channels; c++) {
    for (let h = 0; h < height; h++) {
      for (let w = 0; w < width; w++) {
        const chwIndex = c * width * height + h * width + w;
        const hwcIndex = h * width * channels + w * channels + c;
        // Denormalize pixel values and clip to [0, 255]
        chwData[hwcIndex] = Math.min(
          Math.max(((data[chwIndex] * 0.5) + 0.5) * 255, 0),
          255
        );
      }
    }
  }

  // Convert to an image buffer
  const imageBuffer = Buffer.from(chwData);
  const image = await sharp(imageBuffer, {
    raw: { width, height, channels },
  })
    .toFormat('png') // Convert to PNG
    .toBuffer();

  return image;

}

async function preprocessImageForFloodDetection(imageBuffer) {
  try {
      console.log('Input buffer length:', imageBuffer.length);

      // Resize image to 256x256 and get both data and info
      const { data: resizedImage, info } = await sharp(imageBuffer)
          .resize(256, 256)
          .raw() // Get raw pixel data
          .toBuffer({ resolveWithObject: true });

      console.log('Resized image buffer length:', resizedImage.length);
      console.log('Resized image dimensions:', info.width, 'x', info.height);

      // Convert to float32 normalized tensor
      const float32Data = new Float32Array(resizedImage.length);
      for (let i = 0; i < resizedImage.length; i++) {
          float32Data[i] = resizedImage[i] / 255.0; // Normalize pixel values
      }

      console.log('Float32 data length:', float32Data.length);

      // Create patches of size 16x16 directly from the resized image data
      const patchSize = 16;
      const numPatchesPerRow = info.width / patchSize; // Number of patches per row
      const numPatchesPerColumn = info.height / patchSize; // Number of patches per column
      const totalPatches = numPatchesPerRow * numPatchesPerColumn; // Total number of patches

      const patches = new Float32Array(totalPatches * patchSize * patchSize * 3); // Assuming 3 channels (RGB)

      let patchIndex = 0;
      for (let row = 0; row < numPatchesPerColumn; row++) {
          for (let col = 0; col < numPatchesPerRow; col++) {
              const left = col * patchSize;
              const top = row * patchSize;

              // Extract and flatten the patch directly from resizedImage
              for (let y = 0; y < patchSize; y++) {
                  for (let x = 0; x < patchSize; x++) {
                      const pixelIndex = ((top + y) * info.width + (left + x)) * 3; // RGB channels
                      const patchPixelIndex = (patchIndex * patchSize * patchSize * 3) + (y * patchSize + x) * 3;
                      patches[patchPixelIndex] = float32Data[pixelIndex];       // R
                      patches[patchPixelIndex + 1] = float32Data[pixelIndex + 1]; // G
                      patches[patchPixelIndex + 2] = float32Data[pixelIndex + 2]; // B
                  }
              }
              patchIndex++;
          }
      }

      // Hard-code the tensor shape to [1, 256, 768]
      const tensorShape = [1, 256, 768]; // Assuming this is the expected input shape

      // Create an ONNX Runtime tensor from the patches with hard-coded dimensions
      const tensor = new ort.Tensor(
          'float32',   // Data type
          patches.slice(0, tensorShape[1] * tensorShape[2]),     // Data (ensure it fits expected size)
          tensorShape   // Dimensions: [batch_size=1, height=256, width=768]
      );

      return tensor;
  } catch (error) {
      console.error('Preprocessing error:', error);
      throw error;
   }
}

app.post('/flood', async (req, res) => {
  try {
      // Check for base64 image in request body
      const { image } = req.body;
      if (!image) {
          return res.status(400).json({ error: 'No image provided' });
      }

      // Decode base64 image
      const imageBuffer = Buffer.from(image, 'base64');
      // Convert input image to raw pixels using Sharp


      // Preprocess image (assuming this function is already defined)
      const processedImage = await preprocessImageForFloodDetection(imageBuffer);

      
      const inputImageMetadata = await sharp(imageBuffer)
      .raw()
      .toBuffer({ resolveWithObject: true });

      // Create OpenCV matrix from the raw pixel data
      const resultMat = cv.matFromArray(
      inputImageMetadata.info.height, 
      inputImageMetadata.info.width, 
      cv.CV_8UC3, 
      inputImageMetadata.data
      );


      // Run inference
      const feeds = {};
      feeds[floodSession.inputNames[0]] = processedImage;
      const results = await floodSession.run(feeds);
      
      // Get output tensor (adjust the key based on your model's output)
      const outputTensor = results[floodSession.outputNames[0]];
      const predictionArray = outputTensor.data;

      // Denormalize prediction and convert to Uint8Array
      const denormalizedPrediction = new Uint8Array(predictionArray.length);
      for (let i = 0; i < predictionArray.length; i++) {
          denormalizedPrediction[i] = predictionArray[i] > 0.5 ? 255 : 0; // Convert to binary mask
      }

      // Create OpenCV Mat from Uint8Array directly for the mask
      const maskMat = cv.matFromArray(256, 256, cv.CV_8UC1, denormalizedPrediction);

      // Prepare destination Mat for drawing contours
      // resultMat = new cv.Mat.zeros(maskMat.rows, maskMat.cols, cv.CV_8UC3);
      
      // Find contours
      let contours = new cv.MatVector();
      let hierarchy = new cv.Mat();
      
      cv.findContours(maskMat, contours, hierarchy, cv.RETR_CCOMP, cv.CHAIN_APPROX_SIMPLE);
      
      cv.drawContours(resultMat, contours, -1, new cv.Scalar(255, 0, 0), 2);
      // Convert mask Mat to base64 using Buffer
      const maskBuffer = Buffer.from(maskMat.data);
      const maskImageBuffer = await sharp(maskBuffer, {
          raw: { width: maskMat.cols, height: maskMat.rows, channels: 1 }, // Grayscale channel
      })
          .toFormat('png') // Convert to PNG format
          .toBuffer();
      
      const maskBase64 = maskImageBuffer.toString('base64');

      // Convert result image Mat to base64 using Buffer
      const resultBuffer = Buffer.from(resultMat.data);
      
      const resultImageBuffer = await sharp(resultBuffer, {
          raw: { width: resultMat.cols, height: resultMat.rows, channels: 3 }, // RGB channels
      })
          .toFormat('png') // Convert to PNG format
          .toBuffer();
      
      const resultBase64 = resultImageBuffer.toString('base64');

      // Clean up memory
      maskMat.delete(); 
      resultMat.delete(); 
      contours.delete(); 
      hierarchy.delete();

      // Return results including both mask and result images in base64 format and flood detection status
      res.json({
          predicted_mask: maskBase64,
          result_image: resultBase64,
          flood_detected: denormalizedPrediction.some(val => val > 0)
      });

  } catch (error) {
      console.error('Flood Detection Error:', {
          message: error.message,
          stack: error.stack,
          name: error.name
      });
      
      res.status(500).json({ 
          error: 'Flood detection failed',
          details: error.message 
   });
  }
});

app.post("/colorize", async (req, res) => {
  const base64Image = req.body.image;
  if (!base64Image) {
    return res.status(400).send("No image provided");
  }

  try {
    const imageBuffer = Buffer.from(base64Image, "base64");
    console.log("SAR image received, processing...");

    // Preprocess the SAR image
    const imageTensor = await preprocessSarImage(imageBuffer); // Adjust size as needed
    const feeds = { [sarSession.inputNames[0]]: imageTensor };

    // Run inference
    const output = await sarSession.run(feeds);
    const sarOutputTensor = output[sarSession.outputNames[0]];

    // Postprocess the output to get Base64 image
    const colorizedImage = await postprocessSarImage(sarOutputTensor); // Use actual dimensions

    const colorizedBase64 = colorizedImage.toString('base64');
    res.status(200).send({ colorizedImage: colorizedBase64 });
  } catch (error) {
    console.error("Error in /colorize route:", error);
    res.status(500).send({ error: error.message });
  }
});


app.post('/predict', async (req, res) => {
  const base64Image = req.body.image;
  if (!base64Image) {
    return res.status(400).send('No image provided');
  }

  try {
    // Decode Base64 image
    const imageBuffer = Buffer.from(base64Image, 'base64');
    console.log('Crop image received, processing...'); // Debugging line

    // Preprocess image and run model
    const imageTensor = await preprocessImage(imageBuffer);
    const prediction = await runModel(imageTensor);

    // Return prediction
    res.status(200).send({ crop: prediction });
  } catch (error) {
    console.error('Error in /predict route:', error);
    res.status(500).send({ error: error.message });
  }
});


app.post('/predictusingvit',async(req,res)=>{
  const base64Image = req.body.image;
  if(!base64Image){
    return res.status(400).send('No image provided');
  }
  try{
    const imageBuffer = Buffer.from(base64Image,'base64');
    console.log('Crop image received, processing using vit....');
    const imageTensor = await preprocessImage(imageBuffer);
    const prediction = await runVITModel(imageTensor);
    res.status(200).send({crop: prediction});
  }catch(error){
    console.log('Error in /predictusingvit route:',error);
    res.status(500).send({error:error.message});
  }

});
// Parse incoming JSON requests
app.use(bodyParser.json());

app.get('/', (req, res) => {
  res.send('Hello, World! The server is running.');
});

// Endpoint to send OTP via SMS using Twilio Verify API
app.post('/send-otp', (req, res) => {
  const { phoneNumber } = req.body;

  client.verify.v2.services(verifyServiceSid)
  .verifications.create({
    to: phoneNumber,
    channel: 'sms',
  })


    .then(verification => res.status(200).send({ sid: verification.sid }))
    .catch(error => res.status(500).send({ error: error.message }));
});


// Endpoint to verify OTP using Twilio Verify API
app.post('/verify-otp', (req, res) => {
  const { phoneNumber, otp } = req.body;

  client.verify.v2.services(verifyServiceSid)
    .verificationChecks.create({
      to: phoneNumber,
      code: otp,
    })
    .then(verificationCheck => {
      if (verificationCheck.status === 'approved') {
        res.status(200).send({ message: 'OTP verified successfully' });
      } else {
        res.status(400).send({ message: 'Invalid OTP' });
      }
    })
    .catch(error => res.status(500).send({ error: error.message }));
});

// Use HTTP for debugging
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on http://${process.env.SERVER_IP}:${port}`);
});
