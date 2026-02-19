% Variables that can be changed are labeled with (!):

conf = struct;

conf.seed = 106;            % (!) random seed 
conf.center_freq = 3.5e9;   % central frequency [Hz]
conf.bw = 122.88e6;         % bandwidth [Hz]
conf.n_fft = 2048;          % number of subcarriers
conf.n_eff = 1632;          % number of selected subcarriers

conf.speed_kmh = 5;         % (!) user speed [km/h]
conf.sample_rate = 40e-3;   % (!) sample rate of channel measurements [s]. Can be: 5, 10 , 20, 40, 80, 160, 320 ms
conf.track_len_m = 40;      % (!) user track lenght [m]
conf.min_distance_m = 50;   % minimal distance between BS and UE along x axis [m]
conf.n_segments = 2;        % number of uncorrelated channels
conf.segment_overlap = 0.5;         % segment overlapping ratio. in range [0, 1]
conf.use_random_initial_phase = 1;  % random phases per ray
conf.use_absolute_delays = 0;       % LOS path has 0 delay

conf.possible_scenarios = ...   % Channel scenarios possible to appear 
    {'3GPP_38.901_UMa_NLOS', 'BERLIN_UMa_NLOS', 'DRESDEN_UMa_NLOS'};    

%% Base station config
conf.BS = struct;
conf.BS.Ain = 2;                % Number of vertical elements (combined)
conf.BS.Bin = 1;                % Number of horizontal elements (combined)
conf.BS.Cin = conf.center_freq; % Center frequency in Hz
conf.BS.Din = 6;                % Polarization indicator. 6: 45 deg polarized elements
conf.BS.Ein = 0;                % Electric downtilt angle in deg
conf.BS.Fin = 0.35;             % Element spacing
conf.BS.N_ver = 4;              % Number of nested panels in a column
conf.BS.N_hor = 8;              % Number of nested panels in a row
conf.BS.Lin = 0.5;              % Panel spacing in vertical direction (in wavelenghts)
conf.BS.Jin = 0.5;              % Panel spacing in horizontal direction (in wavelenghts)

conf.BS.tilt = "auto";          % angle in plane (YZ) from vector y [deg]
conf.BS.height = 25;            % base station height [m]
%% User config
conf.UE = struct; 
conf.UE.N_ver = 1;              % number of vertical elements
conf.UE.N_hor = 2;              % number of ho  rizontal elements
conf.UE.Din = 6;                % polarization index. 6: 45 deg polarized elements
conf.UE.height = 1.5;           % user height [m]
conf.UE.XY_rotation = 180;      % user orientation in XY plane [m] (To west)

generate_road_channel(conf, true);
