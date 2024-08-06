# Hailo ONNX to HEF Converter

This docker image can be used to convert an ONNX exported **yolov8s model** to Hailo's **HEF format**.
It utilizes the [Hailo Dataflow Compiler](https://hailo.ai/developer-zone/documentation/v3-28-0/?sp_referrer=install/install.html).

## Pre-requisites

- Docker
- ONNX exported model
- Calibration images

## Usage

### 1. Train Model and Export

Train your model with Ultralytics and [export](https://docs.ultralytics.com/modes/export/#why-choose-yolov8s-export-mode) it to ONNX format.

```bash
yolo export model=/path/to/trained/best.pt imgsz=640 format=onnx opset=11
```

For reference see:
- https://docs.ultralytics.com/modes/export/#why-choose-yolov8s-export-mode
- https://github.com/hailo-ai/hailo_model_zoo/blob/master/training/yolov8/README.rst

### 2. Clone the repository

> [!NOTE]  
> The cloning takes longer than usual because of a large whl file.

```bash
git clone https://github.com/cyclux/HailoConverter.git
cd HailoConverter
```

### 3. Build the docker image

```bash
docker build -t hailo_converter .
```

### 4. Prepare model and calibration images 

Place the **ONNX model** and **calibration images** (`calibration_imgs` folder) in the root directory of the repository.

> [!NOTE] 
> The calibration set should be real images that are a subset of the training dataset.
> They should be diverse and representative of the dataset. Max 64 images are used.

```bash
cp /path/to/best.onnx best.onnx
cp -r /path/to/calibration_imgs calibration_imgs
```

### 5. Run the docker image

Ensure that the current directory is where the ONNX model and calibration images are placed.

> [!IMPORTANT]
> They need to be named `best.onnx` and `calibration_imgs`.

```bash
docker run -v $(pwd):/workspace --gpus all --ipc=host hailo_converter:latest
```

This will run the following command inside the docker container:

```bash
hailomz compile --ckpt best.onnx --hw-arch hailo8l --calib-path calibration_imgs/ --yaml yolov8s_custom.yaml --model-script yolov8s_custom.alls --classes 1
```

> [!NOTE]
> The `Using deprecated NumPy API` warning at the beginning can be ignored it seems.

> [!NOTE]  
> The compilation can take a considerable amount of time.

Once successful, the HEF model will be saved in the same directory.
