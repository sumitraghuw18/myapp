FROM python:3.9-slim
WORKDIR /app

# Install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir gunicorn

# Copy app code
COPY . .

EXPOSE 5000

# Run the Flask app with gunicorn
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5000", "main:app"]
