import numpy as np
import cv2
import imutils
import easyocr
import time
from imutils.video import FileVideoStream

# Initialize EasyOCR reader
reader = easyocr.Reader(['en'])

def detect_text(frame):
    results = reader.readtext(frame)
    text_boxes = []
    texts = []
    for (bbox, text, prob) in results:
        if prob < 0.5:  # Filter out low-confidence detections
            continue
        (top_left, top_right, bottom_right, bottom_left) = bbox
        x_min = int(min(top_left[0], bottom_left[0]))
        y_min = int(min(top_left[1], top_right[1]))
        x_max = int(max(bottom_right[0], top_right[0]))
        y_max = int(max(bottom_right[1], bottom_left[1]))
        w = x_max - x_min
        h = y_max - y_min
        text_boxes.append((x_min, y_min, w, h))
        texts.append(text)
    return text_boxes, texts

def get_background_color(frame, box, margin=5):
    x, y, w, h = box
    bg_x1 = max(0, x - margin)
    bg_y1 = max(0, y - margin)
    bg_x2 = min(frame.shape[1], x + w + margin)
    bg_y2 = min(frame.shape[0], y + h + margin)
    
    bg_region = frame[bg_y1:bg_y2, bg_x1:bg_x2]
    return bg_region

def get_average_color(region):
    if region.size == 0:
        return np.array([0, 0, 0])
    return np.mean(region, axis=(0, 1))

def calculate_contrast(color1, color2):
    luminance1 = 0.299*color1[2] + 0.587*color1[1] + 0.114*color1[0]
    luminance2 = 0.299*color2[2] + 0.587*color2[1] + 0.114*color2[0]
    contrast = abs(luminance1 - luminance2)
    return contrast

def evaluate_contrast(contrast, threshold=100):
    return contrast < threshold

def analyze_contrast_errors_in_image(image_path):
    frame = cv2.imread(image_path)
    frame = imutils.resize(frame, width=450)
    text_boxes, texts = detect_text(frame)
    contrast_error_count = 0
    checked_boxes = []

    for box, text in zip(text_boxes, texts):
        if box[2] == 0 or box[3] == 0:
            continue

        if box in checked_boxes:
            continue
        checked_boxes.append(box)

        text_region = frame[box[1]:box[1] + box[3], box[0]:box[0] + box[2]]
        bg_region = get_background_color(frame, box)
        
        text_color = get_average_color(text_region)
        bg_color = get_average_color(bg_region)
        
        contrast = calculate_contrast(text_color, bg_color)
        if evaluate_contrast(contrast):
            contrast_error_count += 1
            print(f"Contrast error detected for text '{text}' in box {box}")

    return contrast_error_count

def analyze_contrast_errors_in_video(filename, target_frame_rate):
    fvs = FileVideoStream(filename).start()
    time.sleep(1.0)
    
    video = cv2.VideoCapture(filename)
    frame_rate = video.get(cv2.CAP_PROP_FPS)
    frame_count = int(video.get(cv2.CAP_PROP_FRAME_COUNT))
    video_duration = frame_count / frame_rate
    video.release()

    skip_frames = int(frame_rate // target_frame_rate)
    num_frames = int((frame_rate // skip_frames) * video_duration)
    
    contrast_error_count = 0
    frame_num = 0
    processed_frames = 0
    checked_boxes = []

    while fvs.more() and processed_frames < num_frames:
        frame = fvs.read()
        frame_num += 1

        if frame is not None:
            if frame_num % skip_frames != 0:
                continue

            frame = imutils.resize(frame, width=450)
            text_boxes, texts = detect_text(frame)
            processed_frames += 1
            previous_texts = []
            for box, text in zip(text_boxes, texts):
                if box[2] == 0 or box[3] == 0:
                    continue

                if text in previous_texts:
                    continue
                previous_texts.append(text)

                if box in checked_boxes:
                    continue
                checked_boxes.append(box)
                
                text_region = frame[box[1]:box[1] + box[3], box[0]:box[0] + box[2]]
                bg_region = get_background_color(frame, box)
                
                text_color = get_average_color(text_region)
                bg_color = get_average_color(bg_region)
                
                contrast = calculate_contrast(text_color, bg_color)
                if evaluate_contrast(contrast):
                    contrast_error_count += 1
                    print(f"Frame {frame_num}: Contrast error detected for text '{text}' in box {box}")

        else:
            break

    fvs.stop()
    return contrast_error_count
