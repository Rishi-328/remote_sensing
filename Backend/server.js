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

const sarModelPath = path.join(__dirname, "sar2rgb.onnx"); // Path to SAR colorization ONNX model
let sarSession;


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
