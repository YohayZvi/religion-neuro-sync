function shuf_data = phase_shuf_group_data(real_data)
% -------------------------------------------------------------------
% phase_shuf_group_data.m
%
% Performs phase randomization on group fMRI time-series data.
%
% For each subject (column) the phase is permuted independently,
% while preserving conjugate symmetry so that the inverse FFT yields
% real time-domain signals.
%
% Inputs:
%   real_data  – numeric 3D array (time samples × subjects × voxels)
%
% Output:
%   shuf_data  – phase-scrambled data (time samples × subjects × voxels)
%
% Notes:
%   • Positive and negative frequency components are symmetrized:
%       phi(w)  =  rand phase(w) - rand phase(-w)
%       phi(-w) = -phi(w)
%   • This ensures the inverse FFT returns real values.
%
% Author:    unknown
% Tested:    March 2023
% Checked:   May 2025
% -------------------------------------------------------------------

% Extract dimensions
[Nsamp, Nsubjs, Nvxls] = size(real_data);  

% Transform to frequency domain along the time dimension
Fx = fft(real_data,[],1);
clear real_data 
 

% Determine positive & negative frequency indices
if mod(Nsamp,2) == 0
    posfreqs = 2:(Nsamp/2);
    negfreqs = Nsamp : -1 : (Nsamp/2)+2;
else
    posfreqs = 2:(Nsamp+1)/2;
    negfreqs = Nsamp : -1 : (Nsamp+1)/2 + 1;
end

% Extract amplitudes and phases
x_amp = abs(Fx);  
x_phase = atan2(imag(Fx), real(Fx)); 
J = sqrt(-1);  % imaginary unit


% Prepare containers
rand_phase = zeros(Nsamp,Nsubjs,Nvxls); 
sym_phase = zeros(Nsamp,Nsubjs,Nvxls); 

% Generate independent permutations for each subject
[~,index] = sort(rand(Nsamp,Nsubjs)); 

% Apply random shuffling of phase per subject
for s = 1:Nsubjs  
    rand_phase(:,s,:)=x_phase(index(:,s),s,:);
end

clear Fx index x_phase 
% Enforce conjugate symmetry of phase
sym_phase(posfreqs,:,:) = rand_phase(posfreqs,:,:) - rand_phase(negfreqs,:,:); %symmetrize permuted phases so phi(w) = -phi(-w)
sym_phase(negfreqs,:,:) = rand_phase(negfreqs,:,:) - rand_phase(posfreqs,:,:); %this quarantees the iFFT is real

clear rand_phase

% Reconstruct Fourier components with scrambled phase
z = x_amp.*exp(J.*sym_phase); 

% Inverse FFT to time domain
shuf_data = ifft(z); 

end
