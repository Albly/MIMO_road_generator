function generate_road_channel(conf, debug_mode)

rng(conf.seed);     % fix random seed
scenario_idxs = randi(length(conf.possible_scenarios), 1, conf.n_segments); % select scenario idxs for segments
conf.scenarios = conf.possible_scenarios(scenario_idxs);                    % scenarios per segment

az_shift = (rand - 0.5)*2 * 80;
el_shift = (rand - 0.5)*2 * 80;

%% Simulation parameters config
simpar = qd_simulation_parameters;
simpar.center_frequency = conf.center_freq;                                 % set center frequency
simpar.use_absolute_delays = conf.use_absolute_delays;                      
simpar.show_progress_bars = 0;                                              % don't show progress bars
simpar.use_random_initial_phase = conf.use_random_initial_phase;
simpar.set_speed(conf.speed_kmh, conf.sample_rate);                         % set speed and sample rate

%% BS antenna
BS = conf.BS; 
if BS.tilt == "auto"
   % Such tilt, that antenna norm is directed to the middle of track
   BS.tilt = rad2deg(pi/2 - atan2(conf.min_distance_m + conf.track_len_m/2 , conf.BS.height)); 
   BS.tilt = BS.tilt + el_shift;
end
tx_ant = qd_arrayant('3gpp-mmw', BS.Ain, BS.Bin, BS.Cin, BS.Din, BS.Ein, BS.Fin, BS.N_ver, BS.N_hor, BS.Lin, BS.Jin); % bs antenna object
tx_ant.rotate_pattern(BS.tilt, 'y');    % apply tilt
tx_ant.rotate_pattern(az_shift, 'z')
BS.Pos = [0; 0; BS.height];             % base station position

%% User antenna
UE = conf.UE;                   
rx_ant = qd_arrayant('3gpp-3d', UE.N_ver, UE.N_hor, conf.center_freq, UE.Din, [], 1); % ue antenna object
rx_ant.rotate_pattern(UE.XY_rotation, 'z');         % user orientation in XY plane

%% User track  
[x_ue, y_ue, alpha] = random_line_in_sector(conf.track_len_m, conf.min_distance_m); % generate params of line track
rx_center_pos = [x_ue; y_ue; UE.height];                                   % initial user position
track = qd_track('linear', conf.track_len_m, alpha);                       % user track object
track.initial_position = rx_center_pos;                                    % apply ue position

track.interpolate_positions(simpar.samples_per_meter);                     % sample track using speed and sample rate
segment_len_snap = floor(track.no_snapshots / conf.n_segments);            % segment length in samples
track.segment_index = 1:segment_len_snap:(track.no_snapshots-1);           % segment starting sample indices
track.scenario = conf.scenarios;                                           % apply scenarios for segments 
%% layout 
layout = qd_layout(simpar);                                                
layout.tx_array = tx_ant;
layout.rx_array = rx_ant;
layout.rx_track = track;

layout.rx_position = rx_center_pos;
layout.tx_position = BS.Pos;

%% builder
builder = layout.init_builder();
builder.gen_parameters(5);                                                 % generate environment parameters

chan = builder.get_channels();                                             % generate channels
chan = merge(chan, conf.segment_overlap);                                  % merge segments wiht overlaping into one channel
%% Channel 
H = chan.fr(conf.bw, conf.n_fft);                                          % Band-limited channel
H = H(:, :, 1:conf.n_eff, :);                                              % Selection data subcariers
H = single(H);

[Nrx, Ntx, Nf, Nt] = size(H);

filename = strcat("data/channel_seed_",num2str(conf.seed), ".mat");
save(filename, "H", "conf", "-v7.3");                                      % Save channel file

%% image plotting
if debug_mode
    H = reshape(H, [Nrx, 2, BS.N_ver, BS.N_hor, Nf, Nt]);    

    layout.visualize();                                                    % visualize BS, UE positions, ue track 
    figure();
    tiledlayout(4, 1, "TileSpacing", "none")
    
    %% Power
    nexttile
    P = 10*log10(squeeze(mean(abs(H).^2, [1,2,3,4,5])));                   % Calculate power per each time sample in log scale
    plot(P);
    ylabel('Power dB');
    title('Power, Delay, Azimuth, Elevation profiles')
    
    %% Power delay profile plot
    pdp = squeeze(10*log10(mean(abs(ifft(H, [], 5)).^2, [1,2,3,4])));      % Calculate power-delay profile in log scale
    
    nexttile
    imagesc(pdp);
    ylabel('Delay bin');
    
    %% Power azimuth profile plot
    pap = squeeze(10*log10(mean(abs(fft(H, [], 4)).^2, [1,2,3,5])));       % Calculate power-azimuth profile in log scale
    
    nexttile
    imagesc(pap);
    ylabel('Azimuth bin');
    
    %% Power elevation profile plot
    pep = squeeze(10*log10(mean(abs(fft(H, [], 3)).^2, [1,2,4,5])));       % Calculate power-elevation profile in log scale
    
    nexttile
    imagesc(pep);
    ylabel('Elevation bin');
    xlabel('Time snapshot');
end
end

