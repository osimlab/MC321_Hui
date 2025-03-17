// Test the FFT_1D function.
use DigiProcessing;
use Math;

proc main() {
  // Example usage:
  const N = 1024;
  const D = {0..N-1};
  var input: [D] complex;
  const freq = 10.0;
  const sampleRate = 512.0;

  // Initialize the input array with a sine wave (imaginary part defaults to 0).
  for i in D do
    input[i] = sin(2.0 * pi * freq * (i / sampleRate));

  writeln("Input Signal:", input);

  // Compute the FFT using the FFT_1D function.
  var fftResult = FFT_1D(input);

  writeln("Forward FFT Spectrum:");
  writeln("FFT Signal:", fftResult);
}