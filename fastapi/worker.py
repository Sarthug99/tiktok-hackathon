import firebase_admin
from firebase_admin import credentials, firestore
import time
from utils import *
from contrast_error_detection import *

# Initialize Firebase Admin SDK
cred = credentials.Certificate("./tiktok-clone-5c370-firebase-adminsdk-74df0-97836e6efe.json")
firebase_admin.initialize_app(cred)

# Initialize Firestore client
db = firestore.client()

# Collection name
collection_name = "job_processing"

# Callback function to handle updates
def on_snapshot(col_snapshot, changes, read_time):
    print(f"Snapshot received at {read_time}")
    for change in changes:
        if change.type.name == 'ADDED' and change.document.to_dict().get('status') == 'N':
            print(f"New job: {change.document.id}")
            job = change.document.to_dict()
            print(f"Job ID: {change.document.id}, URL: {job.get('postId')}, Status: {job.get('status')}, Video: {job.get('isVideo')}")
            docs = db.collection("posts").document(job.get('postId')).get()
            docs = docs.to_dict()
            if job.get('isVideo'):
                download_file(docs.get('postUrl'), f"{job.get('postId')}.mp4")
                result = upload_video(f"{job.get('postId')}.mp4")
                result["Number of Contrast Errors"] = analyze_contrast_errors_in_video(f"{job.get('postId')}.mp4", 3)
                db.collection(collection_name).document(change.document.id).update({"result": result, "status": "C"})
            else:
                download_file(docs.get('postUrl'), f"{job.get('postId')}.jpeg")
                result = {}
                result["Number of Contrast Errors"] = analyze_contrast_errors_in_image(f"{job.get('postId')}.jpeg")
                db.collection(collection_name).document(change.document.id).update({"result": result, "status": "C"})

        elif change.type.name == 'MODIFIED':
            print(f"Modified job: {change.document.id}")
            job = change.document.to_dict()
            print(f"Job ID: {change.document.id}, URL: {job.get('url')}, Status: {job.get('status')}")
        elif change.type.name == 'REMOVED':
            print(f"Removed job: {change.document.id}")

# Watch the collection
col_query = db.collection(collection_name)
query_watch = col_query.on_snapshot(on_snapshot)

# Keep the script running
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("Stopping the listener...")
    query_watch.unsubscribe()