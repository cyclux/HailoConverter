# Hailo ONNX to HEF Converter

This docker image is used to convert an ONNX exported yolov8 model to Hailo's HEF format.
Basically, it uses the [Hailo Dataflow Compiler](https://hailo.ai/developer-zone/documentation/v3-28-0/?sp_referrer=install/install.html) to convert the ONNX model to HEF format.

## Pre-requisites

- Docker
- ONNX exported model
- Calibration images

## Usage

### Train Model and Export

Train your model with Ultralytics and [export](https://docs.ultralytics.com/modes/export/#why-choose-yolov8s-export-mode) it to ONNX format.

```bash
yolo export model=/path/to/trained/best.pt imgsz=640 format=onnx opset=11
```

For reference see: https://docs.ultralytics.com/modes/export/#why-choose-yolov8s-export-mode and https://github.com/hailo-ai/hailo_model_zoo/blob/master/training/yolov8/README.rst

### Clone the repository

```bash
git clone https://github.com/cyclux/HailoConverter.git
cd HailoConverter
```

### Build the docker image

```bash
docker build -t HailoConverter .
```

### Prepare model and calibration images 

Place the ONNX model and calibration images in the root directory of the repository.
    > NOTE: The calibration set should be real images that are a subset of the training dataset.
    They should be diverse and representative of the dataset. Max 64 images are used.

```bash
cp /path/to/best.onnx best.onnx
cp -r /path/to/calibration_imgs calibration_imgs
```

### Run the docker image

Ensure that the current directory is where the ONNX model and calibration images are placed.
    > NOTE: They need to be named "best.onnx" and "calibration_imgs".

```bash
docker run -v $(pwd):/home/hailo --gpus all --ipc=host HailoConverter
```

This will run the following command:

```bash
hailomz compile --ckpt best.onnx --hw-arch hailo8l --calib-path calibration_imgs/ --yaml yolov8s_custom.yaml --model-script yolov8s_custom.alls --classes 1
```

The compilation can take a considerable amount of time.
Once successful, the HEF model will be saved in the same directory.
