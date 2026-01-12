classdef Audio_Equalizer_ < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        KeyPress             matlab.ui.control.Button
        TREBLESlider         matlab.ui.control.Slider
        TREBLESliderLabel    matlab.ui.control.Label
        MIDSlider            matlab.ui.control.Slider
        MIDSliderLabel       matlab.ui.control.Label
        BASSSlider           matlab.ui.control.Slider
        BASSSliderLabel      matlab.ui.control.Label
        StopButton           matlab.ui.control.Button
        PlayProcessedButton  matlab.ui.control.Button
        PlayOriginalButton   matlab.ui.control.Button
        LoadAudioButton      matlab.ui.control.Button
        FreqFilteredAxes     matlab.ui.control.UIAxes
        TimeFilteredAxes     matlab.ui.control.UIAxes
        FreqOriginalAxes     matlab.ui.control.UIAxes
        TimeOriginalAxes     matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        original_audio=[] %original audio loaded
        fs=44100 %sample frequency
        processed_audio=[] %EQ's audio

        %filter coefficients
        b_bass=[]
        b_mid=[]
        b_treble=[]
    end
    
    methods (Access = private)
        function plot_time_domain(app,audio,fs,titleText,ax)
            t=(0:length(audio)-1)/fs;
            X=mean(audio,2);
            plot(ax,t,X);
            xlabel(ax,'Time (s)');
            ylabel(ax,'Amplitude');
            title(titleText);
            grid (ax,'on'); 
        end

        function plot_freq_domain(app,audio,fs,titleText,ax)
            N1=length(audio);
            X= mean(audio,2);
            Y = fft(X);
            % Frequency vector
            f = (0:N1-1)*(fs/N1);  % Frequency axis Fs/N -> sample taken in one sec
            plot(ax, f(1:N1/2), abs(Y(1:N1/2)));  % Plot only first half (Nyquist)
            title(ax, titleText);
            xlabel(ax, 'Frequency (Hz)');
            ylabel(ax,'Magnitude');
            grid (ax, 'on');
        end
        
        function processAudio(app)
            if isempty(app.original_audio)
                return;
            end

            %Connecting Slider and gain values
            bass_gain_db = app.BASSSlider.Value;
            mid_gain_db = app.MIDSlider.Value;
            treble_gain_db = app.TREBLESlider.Value;

            %Converting dB into linear gains
            G_bass=10^(bass_gain_db/20);
            G_mid=10^(mid_gain_db/20);
            G_treble=10^(treble_gain_db/20);

            %Making audio as mono
            X=mean(app.original_audio,2);
            
            y_bass=filter(app.b_bass,1,X)*G_bass;
            y_mid=filter(app.b_mid,1,X)*G_mid;
            y_treble=filter(app.b_treble,1,X)*G_treble; 

            %Combine all the bands
            app.processed_audio = y_bass + y_mid + y_treble;

            %To prevent clipping
            max_val = max(abs(app.processed_audio));
            if max_val > 1.0
                app.processed_audio = app.processed_audio/max_val;
            end
        end
        
        function updateOriginalPlots(app)
            if isempty(app.original_audio)
                return;
            end

            cla(app.TimeOriginalAxes);
            cla(app.FreqOriginalAxes);

            %plot time domain
            plot_time_domain(app, app.original_audio, app.fs, 'Original Audio (Time Domain)', app.TimeOriginalAxes);
            %plot frequency domain
            plot_freq_domain(app, app.original_audio, app.fs, 'Original Audio (Frequency Domain)', app.FreqOriginalAxes);

        end
        
        function updateFilteredPlots(app)
            if isempty(app.processed_audio)
                return;
            end

            %clearing axes
            cla(app.TimeFilteredAxes);
            cla(app.FreqFilteredAxes);

            %plot time domain
            plot_time_domain(app, app.processed_audio, app.fs, 'Filtered Audio (Time Domain)', app.TimeFilteredAxes);
            %plot frequency domain
            plot_freq_domain(app, app.processed_audio, app.fs, 'Filtered Audio (Frequency Domain)', app.FreqFilteredAxes);
            
        end

    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LoadAudioButton
        function LoadAudioButtonPushed(app, event)
            disp('Load button clicked!');
            % Open file dialog
            [file, path] = uigetfile({'*.wav;*.mp3', 'Audio Files'});
            if file ~= 0
                try
                    % Load audio
                    [app.original_audio, app.fs] = audioread(fullfile(path, file));
                    
                    % Convert to mono if stereo
                    if size(app.original_audio, 2) == 2
                        app.original_audio = mean(app.original_audio, 2);
                    end
                    
                    % Design filters
                    order = 50;
                    app.b_bass = fir1(order, 300/(app.fs/2), 'low');
                    app.b_mid = fir1(order, [300, 4000]/(app.fs/2));
                    app.b_treble = fir1(order, 4000/(app.fs/2), 'high');
                    
                    % Process with current slider values
                    processAudio(app);
                    
                    % Update plots
                    updateOriginalPlots(app);
                    updateFilteredPlots(app);
                    
                    % Enable buttons
                    app.PlayOriginalButton.Enable = 'on';
                    app.PlayProcessedButton.Enable = 'on';
                    
                    disp('Audio loaded successfully!');
                    
                catch ME
                    errordlg(sprintf('Error loading audio: %s', ME.message), 'Error');
                end
            end
        end

        % Value changing function: BASSSlider
        function BASSSliderValueChanging(app, event)
            changingValue = event.Value;
            if ~isempty(app.original_audio)
                processAudio(app);
                updateFilteredPlots(app);
            end
        end

        % Value changing function: MIDSlider
        function MIDSliderValueChanging(app, event)
            changingValue = event.Value;
            if ~isempty(app.original_audio)
                processAudio(app);
                updateFilteredPlots(app);
            end
        end

        % Value changing function: TREBLESlider
        function TREBLESliderValueChanging(app, event)
            changingValue = event.Value;
            if ~isempty(app.original_audio)
                processAudio(app);
                updateFilteredPlots(app);
            end
        end

        % Button pushed function: PlayOriginalButton
        function PlayOriginalButtonPushed(app, event)
            if ~isempty(app.original_audio)
                sound(app.original_audio, app.fs);
            end
        end

        % Button pushed function: PlayProcessedButton
        function PlayProcessedButtonPushed(app, event)
            if ~isempty(app.processed_audio)
                sound(app.processed_audio, app.fs);
            end
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            clear sound;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 786 499];
            app.UIFigure.Name = 'MATLAB App';

            % Create TimeOriginalAxes
            app.TimeOriginalAxes = uiaxes(app.UIFigure);
            title(app.TimeOriginalAxes, 'Original Audio (Time domain)')
            xlabel(app.TimeOriginalAxes, 'Time (seconds)')
            ylabel(app.TimeOriginalAxes, 'Amplitude')
            zlabel(app.TimeOriginalAxes, 'Z')
            app.TimeOriginalAxes.FontSize = 11;
            app.TimeOriginalAxes.Position = [317 233 213 167];

            % Create FreqOriginalAxes
            app.FreqOriginalAxes = uiaxes(app.UIFigure);
            title(app.FreqOriginalAxes, 'Original Audio (Frequency domain)')
            xlabel(app.FreqOriginalAxes, 'Frequency (Hz)')
            ylabel(app.FreqOriginalAxes, 'Magnitude')
            zlabel(app.FreqOriginalAxes, 'Z')
            app.FreqOriginalAxes.FontSize = 11;
            app.FreqOriginalAxes.Position = [541 233 213 167];

            % Create TimeFilteredAxes
            app.TimeFilteredAxes = uiaxes(app.UIFigure);
            title(app.TimeFilteredAxes, 'Filtered Audio (Time domain)')
            xlabel(app.TimeFilteredAxes, 'Time (seconds)')
            ylabel(app.TimeFilteredAxes, 'Amplitude')
            zlabel(app.TimeFilteredAxes, 'Z')
            app.TimeFilteredAxes.FontSize = 11;
            app.TimeFilteredAxes.Position = [317 67 213 167];

            % Create FreqFilteredAxes
            app.FreqFilteredAxes = uiaxes(app.UIFigure);
            title(app.FreqFilteredAxes, 'Filtered Audio (Frequency domain)')
            xlabel(app.FreqFilteredAxes, 'Frequency (Hz)')
            ylabel(app.FreqFilteredAxes, 'Magnitude')
            zlabel(app.FreqFilteredAxes, 'Z')
            app.FreqFilteredAxes.FontSize = 11;
            app.FreqFilteredAxes.Position = [541 67 213 167];

            % Create LoadAudioButton
            app.LoadAudioButton = uibutton(app.UIFigure, 'push');
            app.LoadAudioButton.ButtonPushedFcn = createCallbackFcn(app, @LoadAudioButtonPushed, true);
            app.LoadAudioButton.Position = [51 426 140 42];
            app.LoadAudioButton.Text = 'Load Audio';

            % Create PlayOriginalButton
            app.PlayOriginalButton = uibutton(app.UIFigure, 'push');
            app.PlayOriginalButton.ButtonPushedFcn = createCallbackFcn(app, @PlayOriginalButtonPushed, true);
            app.PlayOriginalButton.Position = [227 426 140 42];
            app.PlayOriginalButton.Text = 'Original Audio';

            % Create PlayProcessedButton
            app.PlayProcessedButton = uibutton(app.UIFigure, 'push');
            app.PlayProcessedButton.ButtonPushedFcn = createCallbackFcn(app, @PlayProcessedButtonPushed, true);
            app.PlayProcessedButton.Position = [402 426 140 42];
            app.PlayProcessedButton.Text = 'Processed Audio';

            % Create StopButton
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [583 426 140 42];
            app.StopButton.Text = 'Stop';

            % Create BASSSliderLabel
            app.BASSSliderLabel = uilabel(app.UIFigure);
            app.BASSSliderLabel.HorizontalAlignment = 'right';
            app.BASSSliderLabel.Position = [43 386 66 24];
            app.BASSSliderLabel.Text = 'BASS';

            % Create BASSSlider
            app.BASSSlider = uislider(app.UIFigure);
            app.BASSSlider.Limits = [-20 20];
            app.BASSSlider.Orientation = 'vertical';
            app.BASSSlider.ValueChangingFcn = createCallbackFcn(app, @BASSSliderValueChanging, true);
            app.BASSSlider.Step = 1;
            app.BASSSlider.Position = [72 49 3 321];

            % Create MIDSliderLabel
            app.MIDSliderLabel = uilabel(app.UIFigure);
            app.MIDSliderLabel.HorizontalAlignment = 'center';
            app.MIDSliderLabel.Position = [128 386 66 24];
            app.MIDSliderLabel.Text = 'MID';

            % Create MIDSlider
            app.MIDSlider = uislider(app.UIFigure);
            app.MIDSlider.Limits = [-20 20];
            app.MIDSlider.Orientation = 'vertical';
            app.MIDSlider.ValueChangingFcn = createCallbackFcn(app, @MIDSliderValueChanging, true);
            app.MIDSlider.Step = 1;
            app.MIDSlider.Position = [157 49 3 321];

            % Create TREBLESliderLabel
            app.TREBLESliderLabel = uilabel(app.UIFigure);
            app.TREBLESliderLabel.HorizontalAlignment = 'center';
            app.TREBLESliderLabel.Position = [216 386 80 24];
            app.TREBLESliderLabel.Text = 'TREBLE';

            % Create TREBLESlider
            app.TREBLESlider = uislider(app.UIFigure);
            app.TREBLESlider.Limits = [-20 20];
            app.TREBLESlider.Orientation = 'vertical';
            app.TREBLESlider.ValueChangingFcn = createCallbackFcn(app, @TREBLESliderValueChanging, true);
            app.TREBLESlider.Step = 1;
            app.TREBLESlider.Position = [259 49 3 321];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Audio_Equalizer_

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end