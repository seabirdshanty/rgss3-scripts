=begin
=====================================================
ALSTSS With Map as Title Screen Script Merge
=====================================================
+ ALSTSS System (Uriel Everos / mikkoman123)
https://www.rpgmakercentral.com/topic/27428-auto-load-skip-title-single-save-system-v1/
+ Map As Title Screen 1.1 (Acezon)
https://forums.rpgmakerweb.com/index.php?threads/map-as-title-screen.10202/

Merged by seabirdshanty
Alone these scripts wouldnt work together,
so I forged them and MADE them work.
PLEASE REPORT ANY ERRORS! I've never scripted with
Ruby before, so im sure theres an accident waiting to happen.

This Script Features the Following:
* Autoload system
* Single Save File system
* Skip Title which can be toggled
* Delete save file using events
* Check if save file exists using events
* Appropriate Title Screen if activated
* 5 Customizable settings
* A Map as your Title Screen!

Added:
++ Quick-Save option
++ Shutdown option customization
++ Custom In-Game Title
- Not sure if Khas's Awesome Light Effects script is still compatable (?)

Known Bugs:
  -> If autosaved while a transition is playing, the fadeout to the save will glitch

=end

$imported = {} if $imported.nil?
$imported["Acezon-MapTitleScreen"] = true

module ALSTSS
##############################################
####            ALSTSS OPTIONS            ####
####--------------------------------------####
####   IMPORTANT NOTE!!!!                 ####
####  It's always better to use a Script  ####
####     call to save using events.       ####
#### USE THIS: 	DataManager.save_game(0)  ####
####--------------------------------------####

  SAVE = "ALSTSS.rvdata2" 
  # Change to whatever save file name you want
  # defaut = ALSTSS.rvdata2
  
  FADE_IN_LOAD = true 
  # Change to false if you dont want a fade in effect on load
  # defaut = true
  
  SAVEMENUACCESS = false 
  # Set to true if you want to be able to access save menu
  # default = false
  
  TITLESKIP = false #true
  # Set to true if you want to be able to skip the title screen
  # default = true
  
  PLAYGAME = "Play Game"
  SHUTDEWN = "Shutdown"
  # Change title screen button
  # default = Play Game
  
  QUICK_SAVE = false
  # Deletes the save file after loading.
  
  CUSTOM_TITLE = false
  CUSTOM_TITLE_TEXT = "Not the actuall game title here"
  # Sets custom title text instead of the one in settings.
  # Completely optional but provides even more customization
  # You can have the Window title and In-game title completely different!
  
end

module Config
 ######################################
 #### Config for the Cutscene Map  ####
 ######################################
 
  # The id of the map you want the title to be displayed.
  Starting_Map_ID = 1

  # Character's position (though he/she is invisible)
  # This feature is useful for large maps.
  X_Pos = 1
  Y_Pos = 1
end

include ALSTSS
include Config

#==============================================================================
#
# Do not modify anything below this line unless you want headaches!!
#
#==============================================================================
# * Allows deletion of save data using call event
#     * ALSTSS_deletesave.delete_save
#==============================================================================
module ALSTSS_deletesave
  def self.delete_save
    if !Dir.glob(SAVE).empty?
      File.delete(SAVE)
    end
  end
end

#==============================================================================
# * Allows checking of the existance of save data
#     for use in conditional branches
#     * ALSTSS_checksave.checkfile == true
#==============================================================================
module ALSTSS_checksave
  def self.checkfile
    if !Dir.glob(SAVE).empty?
      return true
    else
      return false
    end
  end
end


module DataManager

  def self.save_file_exists?
    !Dir.glob(SAVE).empty?
  end
  
  def self.make_filename(index)
    sprintf(SAVE)
  end
  
end


class Scene_MapTitle < Scene_Map
	attr_accessor :character_name
	attr_accessor :character_index 
	
	def start
		DataManager.create_game_objects
		$game_party.setup_starting_members
		$game_map.setup(Config::Starting_Map_ID)
		$game_player.moveto(Config::X_Pos, Config::Y_Pos)
		$game_player.followers.visible = false
		$game_player.refresh
		$game_player.make_encounter_count

		@character_name = $game_player.character_name
		@character_index = $game_player.character_index
		$game_player.set_graphic('', 0)

		$game_system.menu_disabled = true
		Graphics.frame_count = 0
		
		super
		create_foreground
		create_background
		create_command_window
		play_title_music
	end
	
	def update
		# Yami's Title Decoration Compatibility Scriptlet
		if $imported["YSE-TD-VerticalCommand"]
			@command_sprite.each { |sprite|
			sprite.update
			@command_window.index == sprite.id ? sprite.activate : sprite.deactivate
			}
		end
		
		update_basic
		@spriteset.update
		$game_map.update(true)
		update_scene if scene_change_ok?
	end
  
	def update_call_debug
		
	end
  
	def transition_speed
		return 20
	end
  
	def terminate
		super
		dispose_background
		dispose_foreground
		dispose_command_sprite if $imported["YSE-TD-VerticalCommand"]
		SceneManager.snapshot_for_background
	end
	
	def create_background
	  @sprite1 = Sprite.new
	  @sprite1.bitmap = Cache.title1($data_system.title1_name)
	  @sprite2 = Sprite.new
	  @sprite2.bitmap = Cache.title2($data_system.title2_name)
	  center_sprite(@sprite1)
	  center_sprite(@sprite2)
	end
  
	def create_foreground
	  @foreground_sprite = Sprite.new
	  @foreground_sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
	  @foreground_sprite.z = 100
	  draw_game_title if $data_system.opt_draw_title
	end
  
  def dispose_background
	  @sprite1.bitmap.dispose
	  @sprite1.dispose
	  @sprite2.bitmap.dispose
	  @sprite2.dispose
	end
  
	def dispose_foreground
	  @foreground_sprite.bitmap.dispose
	  @foreground_sprite.dispose
	end

	def center_sprite(sprite)
	  sprite.ox = sprite.bitmap.width / 2
	  sprite.oy = sprite.bitmap.height / 2
	  sprite.x = Graphics.width / 2
	  sprite.y = Graphics.height / 2
	end
	
	def create_command_window
	  @command_window = Window_TitleCommand.new
	  @command_window.set_handler(:play, method(:command_play))
	  @command_window.set_handler(:shutdown, method(:command_shutdown))
	end
  
  def command_play
    if File.file?(SAVE) 
      fadeout_all
      DataManager.load_game(0)
      $game_system.on_after_load
      SceneManager.goto(Scene_Map)
      if QUICK_SAVE == true
        ALSTSS_deletesave.delete_save
      end
    else
      fadeout_all
      DataManager.setup_new_game
      $game_map.autoplay
      SceneManager.goto(Scene_Map)
    end
  end

  def command_shutdown
    close_command_window
    fadeout_all
    SceneManager.exit
  end
  
  def close_command_window
    @command_window.close
    update until @command_window.close?
  end
  
  def draw_game_title
	@foreground_sprite.bitmap.font.size = 48
	rect = Rect.new(0, 0, Graphics.width, Graphics.height / 2)
	if CUSTOM_TITLE == true
		@foreground_sprite.bitmap.draw_text(rect, CUSTOM_TITLE_TEXT, 1)
	else
		@foreground_sprite.bitmap.draw_text(rect, $data_system.game_title, 1)
	end
  end

  def play_title_music
	$data_system.title_bgm.play
	RPG::BGS.stop
	RPG::ME.stop
  end     
    
  def terminate
    super
    SceneManager.snapshot_for_background
    if FADE_IN_LOAD
      Graphics.fadeout(Graphics.frame_rate)
    end
    if TITLESKIP
    else
      Graphics.fadeout(Graphics.frame_rate)
      dispose_background
      dispose_foreground
    end
  end
  
  
end

class Scene_Title < Scene_Base

  def start
    super
    #SceneManager.clear
    #Graphics.freeze
    if TITLESKIP
      if File.file?(SAVE) 
        DataManager.load_game(0)
        fadeout_all
        $game_system.on_after_load
        SceneManager.goto(Scene_Map)
      else
        DataManager.setup_new_game
        $game_map.autoplay
        SceneManager.goto(Scene_Map)
      end
    else
      SceneManager.call(Scene_MapTitle)
    end
  end
  
  def terminate
		SceneManager.snapshot_for_background
		Graphics.fadeout(Graphics.frame_rate)
	end
 
end
	

class Window_TitleCommand < Window_Command

  def initialize
    super(0, 0)
    update_placement
    self.openness = 0
    open
  end

  def make_command_list
    add_command(PLAYGAME, :play)
    add_command(SHUTDEWN, :shutdown)
  end
  
end

if SAVEMENUACCESS == false
  class Scene_Menu < Scene_MenuBase
    
    def command_save
      DataManager.save_game(0)
      Sound.play_save
      return_scene
    end
  end


class  Scene_File < Scene_MenuBase
    def start
      super
      alstss_eventsave
      Sound.play_save
    end

	# DO NOT EDIT THESE
    def terminate
    end
    def alstss_eventsave
    end
	#####################
  end

class Scene_Save < Scene_File
    def alstss_eventsave
      DataManager.save_game(0)
      Sound.play_save
      SceneManager.return
    end
  end
 end
