{requirePackages} = require 'atom-utils'
TreeViewOpenFilesView = require './tree-view-open-files-view'

module.exports =
	treeViewOpenFilesView: null

	config:
		maxHeight:
			type: 'integer'
			default: 250
			min: 0
			description: 'Maximum height of the list before scrolling is required. Set to 0 to disable scrolling.'

	activate: (state) ->
		requirePackages('nuclide-file-tree').then ([fileTree]) =>
			@treeViewOpenFilesView = new TreeViewOpenFilesView
			@treeViewOpenFilesView.update();

			atom.commands.add 'atom-workspace', 'nuclide-file-tree:toggle', =>
				@treeViewOpenFilesView.update()

	deactivate: ->
		@treeViewOpenFilesView.destroy()

	serialize: ->
		#TreeViewOpenFilesViewState: @TreeViewOpenFilesView.serialize()
