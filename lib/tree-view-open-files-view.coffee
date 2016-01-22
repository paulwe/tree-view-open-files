{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'event-kit'
_ = require 'lodash'

TreeViewOpenFilesPaneView = require './tree-view-open-files-pane-view'

module.exports =
class TreeViewOpenFilesView
	constructor: (serializeState) ->
		# Create root element

		@resizeTriggers = [];
		@wrap = document.createElement('div')
		@wrap.classList.add('tree-view-open-files-wrap');
		@element = document.createElement('div')
		@wrap.appendChild @element
		@element.classList.add('tree-view-open-files')
		@groups = []
		@paneSub = new CompositeDisposable
		@paneSub.add atom.workspace.observePanes (pane) =>
			@addTabGroup pane
			destroySub = pane.onDidDestroy =>
				destroySub.dispose()
				@removeTabGroup pane
			@paneSub.add destroySub

		@configSub = atom.config.observe 'tree-view-open-files.maxHeight', (maxHeight) =>
			@element.style.maxHeight = if maxHeight > 0 then "#{maxHeight}px" else 'none'

	addTabGroup: (pane) ->
		group = new TreeViewOpenFilesPaneView
		group.setPane pane
		@groups.push group
		@element.appendChild group.element

	removeTabGroup: (pane) ->
		group = _.findIndex @groups, (group) -> group.pane is pane
		@groups[group].destroy()
		@groups.splice group, 1

	# Returns an object that can be retrieved when package is activated
	serialize: ->

	# Tear down any state and detach
	destroy: ->
		@element.remove()
		@paneSub.dispose()
		@configSub.dispose()

	# Toggle the visibility of this view
	toggle: ->
		if @element.parentElement?
			@hide()
		else
			@show()

	hide: ->
		@resizeTriggers.forEach trigger -> trigger.remove()
		@resizeTriggers = [];
		@element?.remove()

	resizeDetector: (handle) ->
		obj = document.createElement('object')
		obj.onload = ->
			this.contentDocument.defaultView.addEventListener 'resize', handle
		obj.classList.add('tree-view-open-files-resize-trigger')
		obj.type = 'text/html'
		obj.data = 'about:blank'
		@resizeTriggers.push(obj);
		return obj

	# Find and nuclide file tree and join its panel
	update: ->
		requirePackages('nuclide-file-tree').then =>
			[panel] = atom.workspace.getLeftPanels().filter (panel) =>
				return panel.item?.firstChild?.classList.contains 'nuclide-ui-panel-component'
			if !panel?.visible
				return @hide()
			fixWidth = _.debounce => @element.style.width = panel.item.firstChild.style.width
			fixHeight = _.debounce => panel.item.style.height = 'calc(100% - ' + @element.scrollHeight + 'px)'
			@wrap.appendChild(@resizeDetector(fixHeight));
			panel.item.parentElement.insertBefore @resizeDetector(fixWidth), panel.item
			panel.item.parentElement.insertBefore @wrap, panel.item
			fixWidth()
			fixHeight()
