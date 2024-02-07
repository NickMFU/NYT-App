# Use the official Flutter image as a base image
FROM cirrusci/flutter:stable

# Set the working directory inside the container
WORKDIR /app

# Copy the pubspec.yaml file to the container
COPY pubspec.yaml .

# Install dependencies
RUN flutter pub get

# Copy the entire project to the container
COPY . .

# Build the Flutter app for release
RUN flutter build apk --release

# Expose port 80 to the outside world
EXPOSE 80

# Command to run the Flutter app
CMD ["flutter", "run", "--release", "-d", "all"]
