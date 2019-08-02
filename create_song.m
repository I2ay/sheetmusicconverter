function create_song(sheetname, pace, output_file)
% Modifiers:
note_radius = 4;

% Reading sheet music ==============================================
music=imread(sheetname);
%tolerance of 5 - meaning only pixels with a value less than 5 are treated as "black"
music_data = music(:,:,1) <= 5; 

% Creating Notes =============================================
Fs = 8192;         % the sampling rate
t = 0:1/Fs:pace;      % an array of t values equally spaced from 0 to pace

frequencies = zeros(64-15, 1);

for n = 16:64
    frequencies(n-15) = 2^((n-49)/12)*440;
end

D3 = sin(2*pi*frequencies(15)*t);
E3 = sin(2*pi*frequencies(17)*t);
F3 = sin(2*pi*frequencies(18)*t);
G3 = sin(2*pi*frequencies(20)*t);
A3 = sin(2*pi*frequencies(22)*t);
B3 = sin(2*pi*frequencies(24)*t);

C4 = sin(2*pi*frequencies(25)*t);
D4 = sin(2*pi*frequencies(27)*t);
E4 = sin(2*pi*frequencies(29)*t);
F4 = sin(2*pi*frequencies(30)*t);
G4 = sin(2*pi*frequencies(32)*t);
A4 = sin(2*pi*frequencies(34)*t);
B4 = sin(2*pi*frequencies(36)*t);

C5 = sin(2*pi*frequencies(37)*t);
D5 = sin(2*pi*frequencies(39)*t);
E5 = sin(2*pi*frequencies(41)*t);
F5 = sin(2*pi*frequencies(42)*t);
G5 = sin(2*pi*frequencies(44)*t);
A5 = sin(2*pi*frequencies(46)*t);
B5 = sin(2*pi*frequencies(48)*t);

C6 = sin(2*pi*frequencies(49)*t);

treble_notes = [C6; B5; A5; G5; F5; E5; D5; C5; B4; A4; G4; F4; E4; D4; C4; B3; A3; G3; F3; E3; D3;];


% Getting notes =================================
[columns, rows] = size(music_data);
top_line = findTopLine(music_data);
song = t;
prev_y = 0;
for r = 1 : rows
    note_found = false;
    new_note = t;
    for c = 1 : columns
        if isNote(c,r , music_data, note_radius)
            if r-prev_y == 0 || r-prev_y > note_radius
                % Check for 'ghost note' - note that may accidentally be found
                % if two notes are too close together
                note_found = true;
                % If more than one note found on one line, add notes together
                % to produce chord
                new_note = new_note + whatNote(c, top_line, note_radius, treble_notes);
            end
        end
    end
    if note_found
        % Find distance to previous note to determine how long to pause
        % between notes
        dist_to_prev_note = (r-prev_y)/(note_radius*8);
        pause = 0:1/Fs:(pace*dist_to_prev_note/4);
        song = [song pause new_note pause];
        prev_y = r;
    end
end

%scale song to avoid peaking
song_scaled = song / max(abs(song));

%write to file
audiowrite(output_file, song_scaled, Fs);



% Auxilliary functions =================================================
    function top_line = findTopLine(music_array)
        %This function finds the very first stave line
        [columns, rows] = size(music_array);
        topLineFound = false;
        %Iterate through music array
        for c = 1 : columns
            for r = 1 : rows
                if music_array(c,r) == 0
                    %If any pixel is white, then this row will not be a
                    %stave line
                    topLineFound = false;
                    break
                end
                topLineFound = true;
            end
            if topLineFound
                top_line = c;
                break
            else
                top_line = 0;
            end
        end
    end

    function output = isNote(c,r, music_array, note_radius)
        %This function determines if given pixel is a note
        [columns, rows] = size(music_array);
        %check pixels in a given radius in the 4 cardinal directions
        for i = -note_radius : note_radius
            if c+i < 1 || r+i < 1 || c+i > columns-1 || r+i > rows-1
                output = false;
                break
            end
            if music_array(c+i,r) && music_array(c,r+i) == 1
                output = true;
            else
                output = false;
                break
            end
        end
        %check diagonal pixels 1 away from center
        if output
            if ~music_array(c-1,r-1) && ~music_array(c-1,r+1) && ~music_array(c+1,r+1) && ~music_array(c+1,r-1)
                output = false;
            end
        end        
    end

    function outNote = whatNote(c, top_line, note_radius, treble_array)
        %This function determines what the actual note is (eg. A, B, C, etc.)
        [m, n] = size(treble_array);
        position = round((c-top_line)/note_radius);
        for note = -7 : m-5 %-7 and -5 as that is how many notes above the top stave line we allow
            if position == note
                outNote = treble_array(note+5,:);
            end
        end
    end
end