/* Install FFTW 
 sudo apt-get update
 sudo apt-get install libfftw3-dev 
 dpkg -L libfftw3-dev
 export CHPL_LIB_PATH=/usr/lib/x86_64-linux-gnu
 echo $CHPL_LIB_PATH
 need to add -lfftw3 
 */
 // This is digitial signal processing module in Chapel
module DigiProcessing {    
    use FFTW;
    use Math;

//--------------------------------------------------------------
// FFT_1D: Perform a 1D forward FFT on a complex array.
//--------------------------------------------------------------
    proc FFT_1D(data: [] complex): [] complex {
      const D = data.domain;
      var data_in: [D] complex;
      var data_out: [D] complex;
      data_in = data;
      var fft = plan_dft(data_in, data_out, FFTW_FORWARD, FFTW_ESTIMATE);
      execute(fft);
      destroy_plan(fft);
      return data_out;
      } 
  
//--------------------------------------------------------------
// IFFT_1D: Perform a 1D inverse FFT on a complex array.
//          Note that FFTW_BACKWARD does not normalize the result,
//          so we divide by the number of points.
//--------------------------------------------------------------
    proc IFFT_1D(data: [] complex): [] complex {
      const D = data.domain;
      var data_in: [D] complex;
      var data_out: [D] complex;
      data_in = data;
      var fft = plan_dft(data_in, data_out, FFTW_BACKWARD, FFTW_ESTIMATE);
      execute(fft);
      destroy_plan(fft);
      // Normalize by dividing by the number of elements.
      for i in D do
        data_out[i] /= D.size: complex;
      return data_out;
    }
  
//--------------------------------------------------------------
// convolve_FFT: Perform circular convolution of two arrays.
//--------------------------------------------------------------
    proc convolve_FFT(f: [] complex, g: [] complex): [] complex {
      // Check that the arrays are defined on the same domain.
      const D = f.domain;
      // Compute FFT of both input arrays.
      var F = FFT_1D(f);
      var G = FFT_1D(g);
      
      // Multiply element-wise in the frequency domain.
      var H: [D] complex;
      for i in D do
        H[i] = F[i] * G[i];
      
      // Compute the inverse FFT to get the circular convolution result.
      var conv = IFFT_1D(H);
      
      return conv;
    }

//--------------------------------------------------------------
// convolve_linear_FFT: Perform linear convolution via FFT using zero-padding.
//--------------------------------------------------------------
  proc convolve_linear_FFT(f: [] complex, g: [] complex): [] complex {
    const Nf = f.domain.size;
    const Ng = g.domain.size;
    const L = Nf + Ng - 1;  // Length of the linear convolution
    const P = {0..L-1};     // New domain for the padded arrays
    
    // Create padded arrays initialized to 0.
    var fPad: [P] complex = 0;
    var gPad: [P] complex = 0;
    
    // Copy original arrays into the padded arrays.
    for i in f.domain do
      fPad[i] = f[i];
    for i in g.domain do
      gPad[i] = g[i];
    
    // Compute FFTs of the padded arrays.
    var F = FFT_1D(fPad);
    var G = FFT_1D(gPad);
    
    var H: [P] complex;
    for i in P do
      H[i] = F[i] * G[i];
    
    // Compute the inverse FFT to obtain the linear convolution.
    var conv = IFFT_1D(H);
    return conv;
  }

}


