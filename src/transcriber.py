import threading

class Transcriber:
    def __init__(self, recorder):
        """Initialize the transcriber with a given recorder instance."""
        self.recorder = recorder
        self.stop_event = threading.Event()
        self.transcription_buffer = []
        self.transcription_lock = threading.Lock()
        self.thread = threading.Thread(target=self._transcription_thread, daemon=False)

    def _transcription_thread(self):
        """Thread function to handle transcription and buffer the results."""
        try:
            while not self.stop_event.is_set():
                text = self.recorder.text()
                if text:
                    with self.transcription_lock:
                        self.transcription_buffer.append(text)
        except Exception as e:
            print(f"transcription_thread encountered an error: {e}")
        finally:
            print("Transcription thread exiting.")

    def start(self):
        """Start the transcription thread."""
        self.thread.start()

    def stop(self):
        """Stop the transcription thread and wait for it to finish."""
        self.stop_event.set()
        self.thread.join()

    def is_running(self):
        """Check if the transcription thread is running."""
        return self.thread.is_alive()

    def is_partial_result(self):
        """Returns True when text is being transcribed, False when the transcription is complete."""
        with self.transcription_lock:
            return not bool(self.transcription_buffer)

    def get_text(self):
        """Retrieves the buffered transcription results."""
        with self.transcription_lock:
            if self.transcription_buffer:
                return self.transcription_buffer.pop(0)
            return ""

