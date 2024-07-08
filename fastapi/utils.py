import requests
import cv2
import numpy as np
import time
from typing import List

def luminance_to_brightness(Y):
    return 413.435 * (0.002745 * Y + 0.0189623) ** 2.22

def analyze_video(video_path, area_threshold=0.35, flash_intensity_threshold=10, flash_frequency_threshold=3, interval=0.04):
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_interval = max(1, int(fps * interval))
    
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    events = []
    prev_brightness = None
    acc_brightness_diff = 0
    frames_since_last_extreme = 0
    
    for frame_number in range(0, frame_count, frame_interval):
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
        ret, frame = cap.read()
        if not ret:
            break
        
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        brightness = luminance_to_brightness(np.mean(gray))
        
        if prev_brightness is not None:
            brightness_diff = brightness - prev_brightness
            if np.sign(brightness_diff) != np.sign(acc_brightness_diff) and acc_brightness_diff != 0:
                events.append((abs(acc_brightness_diff), frames_since_last_extreme, min(brightness, prev_brightness)))
                acc_brightness_diff = 0
                frames_since_last_extreme = 0
            else:
                acc_brightness_diff += brightness_diff
                frames_since_last_extreme += frame_interval
        
        prev_brightness = brightness
    
    cap.release()
    return detect_harmful_flashes(events, fps, area_threshold, flash_intensity_threshold, flash_frequency_threshold)

def detect_harmful_flashes(events, fps, area_threshold, flash_intensity_threshold, flash_frequency_threshold):
    dangerous_sections = []
    for i in range(len(events) - 1):
        window_events = events[i:i+2]
        window_frames = sum(event[1] for event in window_events)
        window_time = window_frames / fps
        
        if window_time < 1 and all(event[0] >= flash_intensity_threshold for event in window_events):
            flash_frequency = 1 / window_time
            if flash_frequency > flash_frequency_threshold and any(event[2] < 160 for event in window_events):
                dangerous_sections.append((events[i][1] / fps, f"Harmful flash detected: {flash_frequency:.2f} Hz"))
    
    return dangerous_sections

def detect_saturated_red(video_path, red_threshold=200, other_threshold=90, area_threshold=0.25):
    cap = cv2.VideoCapture(video_path)
    dangerous_sections = []
    frame_number = 0
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        ycbcr = cv2.cvtColor(frame, cv2.COLOR_BGR2YCrCb)
        y, cr, cb = cv2.split(ycbcr)
        
        red_mask = (y >= 66) & (y <= 104) & (cb >= 72) & (cb <= 110) & (cr >= 218) & (cr <= 255)
        red_area = np.sum(red_mask) / (frame.shape[0] * frame.shape[1])
        
        if red_area >= area_threshold:
            dangerous_sections.append((frame_number / cap.get(cv2.CAP_PROP_FPS), "Saturated red transition"))
        
        frame_number += 1
    
    cap.release()
    return dangerous_sections

def categorize_risk(num_violations):
    if num_violations < 50:
        return "Low"
    elif 50 <= num_violations < 150:
        return "Medium"
    else:
        return "High"
def download_file(url, destination_file_name):
    # Send a GET request to the URL
    response = requests.get(url, stream=True)
    
    # Check if the request was successful
    if response.status_code == 200:
        # Open a local file with write-binary mode
        with open(destination_file_name, 'wb') as file:
            # Iterate over the response data in chunks
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        print(f"File downloaded successfully to {destination_file_name}")
    else:
        print(f"Failed to download file. HTTP Status Code: {response.status_code}")

# Usage example
url = 'https://example.com/path/to/your/file.ext'  # Replace with your URL
destination_file_name = 'path/to/save/your/file.ext'  # Replace with your desired local path


def upload_video(file):
    video_path = f"./{file}"
    
    dangerous_flashes = analyze_video(video_path)
    dangerous_reds = detect_saturated_red(video_path)
    
    dangerous_sections = dangerous_flashes + dangerous_reds
    num_violations = len(dangerous_sections)
    risk_level = categorize_risk(num_violations)
    
    result_html = {
            "Number of Violations": num_violations,
            "Risk Level": risk_level
    }
    
    return result_html
