import cv2
import tifffile as tiff
import numpy as np
import os, sys

def convert_tiff_to_avi(tiff_path, avi_path=None, fps=25):
    print(f"Received TIFF path: {tiff_path}")
    if avi_path is None:
        avi_path = os.path.splitext(tiff_path)[0] + '.avi'
    print(f"Output AVI path set to: {avi_path}")

    try:
        with tiff.TiffFile(tiff_path) as tif:
            frames = tif.asarray()
            print(f"TIFF file loaded. Total frames detected: {frames.shape[0]}")
            print(f"Frames shape: {frames.shape[1:]}")
            print(f"Data type of frames: {frames.dtype}")
            print(f"Pixel value range: {frames.min()} to {frames.max()}")
    except Exception as e:
        print(f"Failed to load TIFF file: {e}")
        return

    try:
        # Lossless codec that supports uint16 data:
        # fourcc = cv2.VideoWriter_fourcc(*'FFV1')
        
        # # High quality lossy codec (only supports uint8 data - but Minian seems to expect this):
        fourcc = cv2.VideoWriter_fourcc(*'H264')
        # fourcc = cv2.VideoWriter_fourcc(*'x264')
        out = cv2.VideoWriter(avi_path, fourcc, fps, (frames.shape[2], frames.shape[1]), isColor=False)

        # # # Using x264's parameters to force high quality
        out.set(cv2.VIDEOWRITER_PROP_QUALITY, 100)

        if not out.isOpened():
            print("VideoWriter failed to open.")
            return
        
        print("VideoWriter object created.")
        
    except Exception as e:
        print(f"Failed to create VideoWriter object: {e}")
        return

    try:
        for i in range(frames.shape[0]):
            frame = frames[i]
            
            # H264 need conversion. Ensure the frame is in the correct dtype for OpenCV.
            # if frame.dtype != np.uint8:
            #     frame = np.clip(frame / 256, 0, 255).astype(np.uint8) 

            # 8 bit rescaling
            min_val = np.min(frame)
            max_val = np.max(frame)
            frame = ((frame - min_val) / (max_val - min_val) * 255).astype(np.uint8)

            # # 10 bit rescaling
            # min_val = np.min(frame)
            # max_val = np.max(frame)
            # frame = ((frame - min_val) / (max_val - min_val) * 1023).astype(np.uint16)

            out.write(frame)
            if i % 100 == 0:
                print(f"Processed frame {i + 1}")
    except Exception as e:
        print(f"Failed during frame processing: {e}")

    out.release()
    if os.path.exists(avi_path) and os.path.getsize(avi_path) > 0:
        print("Conversion completed successfully!")
    else:
        print("Conversion failed or resulted in a 0-byte file.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python convert_tiff_to_avi.py [source file] [destination file] [fps (optional)]")
    elif len(sys.argv) == 2:
        convert_tiff_to_avi(sys.argv[1])
    elif len(sys.argv) == 3:
        convert_tiff_to_avi(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 4:
        convert_tiff_to_avi(sys.argv[1], sys.argv[2], int(sys.argv[3]))

# example usage:
# python convert_tiff_to_avi.py input.tiff output.avi 25

# Installations:
# Install opencv in your environment:
# pip install opencv-python (don't use conda's opencv)
# For H264 codec, you may need to have a full ffmpeg installed on your system (not just essentials). 
# You can download a build from Gyan.dev https://www.gyan.dev/ffmpeg/builds/, e.g., ffmpeg-git-full.7z. Unzip it and add the bin folder to your system path.
# If H264 codec is not found (e.g., ffmpeg -codecs | find "264" does not show it), you can use Cisco's OpenH264 codec. Download openh264-1.8.0-win64.dll from https://github.com/cisco/openh264/releases, unzip it, and place it in the path or in the same directory as the script.
