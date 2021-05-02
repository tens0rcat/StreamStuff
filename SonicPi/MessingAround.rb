# Welcome to Sonic Pi

load_sample :bd_mehackit
load_sample :loop_amen

use_ctrl1 = false
leadsynth = [:piano]
basssynth = [:pluck, :hollow, :subpulse]


# use_ctrl1 = get :use_ctrl1
# leadsynth = get :leadsynth
# basssynth = get :basssynth

with_fx :level, amp: 15 do
  with_fx :reverb, room: 0.6, mix: 0.3 do
    live_loop :midi_control do
      use_real_time
      ctrl, val = sync "/midi:mpk_mini_mk_ii_0:1/control_change"
      #puts ctrl, val
      set :ctrl1, val-64 if (ctrl == 1)
      set :trim1, val-64 if (ctrl == 2)
      set :leadmix, val/32 if (ctrl == 5)
      set :bassmix, val/32 if (ctrl == 6)
      set :drummix, val/32 if (ctrl == 7)
    end
    
    bassbeat= [0.25, 0.5, 0.125, 0.125].ring
    live_loop :BassDrum do
      use_real_time
      mix = 0.5
      if use_ctrl1
        mix = get :drummix
      end
      sample :bd_mehackit,  amp: 1.0 * mix #bd_ada
      sleep bassbeat.tick
    end
    
    live_loop :amen_break do
      use_real_time
      #sync :BassDrum
      mix = 1
      if use_ctrl1
        mix = get :drummix
      end
      sample :loop_amen, beat_stretch: 2, amp: 1.0 * mix
      sleep 2
    end
    
    live_loop :lead do
      use_real_time
      sync :amen_break
      use_random_seed rrand(0,1023)
      use_synth leadsynth[0]
      
      notes = (scale :e3, :dorian, num_octaves: 1).pick(3)
      16.times do
        ofst = 0.0
        mix = 1
        if use_ctrl1
          trim = get :trim1
          ofst = get :ctrl1
          ofst = quantise((ofst / 64.0 * 12.8), 1) + quantise(trim / 2.0, 1)
          puts ofst
          mix = get :leadmix
        end
        mote = notes.choose + ofst
        if mote < 0
          mote = 0
        end
        play mote, release: 0.1, cutoff: rrand(70, 120), amp: 1 * mix
        sleep 0.125
      end
    end
    
    live_loop :bass do
      use_real_time
      loop do
        mix = 1.0
        use_random_seed rrand(0,1023)
        use_synth :sine
        notes = (scale :e1, :dorian, num_octaves: 1).drop_last(1).pick(2)
        16.times do
          if use_ctrl1
            mix = get :bassmix
          end
          n = notes.choose
          time = [0.25, 0.5, 0.1250, 0.125].tick
          use_synth basssynth[0]
          play n, release: time, cutoff: rrand(70, 120), amp: 0.1 * mix
          use_synth basssynth[1]
          play n, release: time, cutoff: rrand(70, 120), amp: 1.0 * mix
          use_synth basssynth[2]
          play n, release: time, cutoff: rrand(70, 120), amp: 0.1 * mix
          sleep time
        end
      end
    end
  end
end