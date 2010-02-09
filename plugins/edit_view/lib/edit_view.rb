
require "edit_view/command"
require "edit_view/document"
require "edit_view/document/command"
require "edit_view/document/controller"
require "edit_view/document/mirror"
require "edit_view/edit_tab"

module Redcar
  class EditView
    include Redcar::Model
    extend Redcar::Observable
    include Redcar::Observable
    
    extend Forwardable

    class << self
      attr_reader :undo_sensitivity, :redo_sensitivity
      attr_reader :focussed_edit_view
    end
    
    # Called by the GUI whenever an EditView is focussed or
    # loses focus. Sends :focussed_edit_view event.
    def self.focussed_edit_view=(edit_view)
      @focussed_edit_view = edit_view
      notify_listeners(:focussed_edit_view, edit_view)
    end
    
    def self.sensitivities
      [
        Sensitivity.new(:edit_tab_focussed, Redcar.app, false, [:tab_focussed]) do |tab|
          tab and tab.is_a?(EditTab)
        end,
        Sensitivity.new(:edit_view_focussed, EditView, false, [:focussed_edit_view]) do |edit_view|
          edit_view
        end,
        Sensitivity.new(:selected_text, Redcar.app, false, [:focussed_tab_selection_changed, :tab_focussed]) do
          if win = Redcar.app.focussed_window
            tab = win.focussed_notebook.focussed_tab
            tab and tab.is_a?(EditTab) and tab.edit_view.document.selection?
          end
        end,
        @undo_sensitivity = 
          Sensitivity.new(:undoable, Redcar.app, false, [:focussed_tab_changed, :tab_focussed]) do
            tab = Redcar.app.focussed_window.focussed_notebook.focussed_tab
            tab and tab.is_a?(EditTab) and tab.edit_view.undoable?
          end,
        @redo_sensitivity = 
          Sensitivity.new(:redoable, Redcar.app, false, [:focussed_tab_changed, :tab_focussed]) do
            tab = Redcar.app.focussed_window.focussed_notebook.focussed_tab
            tab and tab.is_a?(EditTab) and tab.edit_view.redoable?
          end,
        Sensitivity.new(:clipboard_not_empty, Redcar.app, false, [:clipboard_added, :focussed_window]) do
          Redcar.app.clipboard.length > 0
        end
      ]
    end

    def self.font_info
      if Redcar.platform == :osx
        default_font = "Monaco"
        default_font_size = 15
      elsif Redcar.platform == :linux
        default_font = "Monospace"
        default_font_size = 11
      elsif Redcar.platform == :windows
        default_font = "FixedSys"
        default_font_size = 15
      end
      [ ARGV.option("font") || default_font, 
        (ARGV.option("font-size") || default_font_size).to_i ]
    end
    
    def self.font
      font_info[0]
    end
    
    def self.font_size
      font_info[1]
    end
    
    def self.theme
      ARGV.option("theme") || "Twilight"
    end    

    attr_reader :document
    
    def initialize
      create_document
      @grammar = nil
      @focussed = nil
    end
    
    def create_document
      @document = Redcar::Document.new(self)
    end
    
    def_delegators :controller, :undo,      :redo,
                                :undoable?, :redoable?,
                                :reset_undo,
                                :cursor_offset, :cursor_offset=,
                                :scroll_to_line
    
    def grammar
      @grammar
    end
    
    def grammar=(name)
      @grammar = name
      notify_listeners(:grammar_changed, name)
    end
    
    def set_grammar(name)
      @grammar = name
    end
    
    def focus
      notify_listeners(:focussed)
    end
    
    def serialize
      { :contents      => document.to_s,
        :cursor_offset => cursor_offset,
        :grammar       => grammar         }
    end
    
    def deserialize(data)
      self.grammar       = data[:grammar]
      document.text      = data[:contents]
      self.cursor_offset = data[:cursor_offset]
    end
  end
end
