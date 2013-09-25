class bcolor

	mode: 0

	# Single Player : 0, Player Round 1:2, Other 2:2
	player: 1
	opponent: 2
	free: -1
	stop: '#'
	colors: ["#E54661","#FFA644","#998A2F","#2C594F","#002D40"]
	color_count: 5
	user_color: "#808080"
	steps: 0
	board_percentage: 0

	#The actual board.
	board: null
	cell_size: 25
	number_of_rows: 15
	number_of_columns: 15
	canvas: null
	drawing_context: null

	constructor: ->
		@create_canvas()
		@resize_canvas()
		@create_drawing_context()

		@init_board()

	create_canvas: ->
		@canvas = document.createElement 'canvas'
		@canvas.id = 'board'
		document.body.appendChild @canvas
		window.onresize = on_resize

	on_resize = ->
		canvas = document.getElementById 'board'

		height = window.innerHeight
		width = window.innerWidth

		width = Math.floor height * 0.8
		height -= width

		canvas.height = width
		canvas.width = width

		window.gamex.cell_size = width / window.gamex.number_of_rows
		window.gamex.create_drawing_context()
		window.gamex.draw_grid()


	resize_canvas: ->
		#@canvas.height = @cell_size * @number_of_rows
		#@canvas.width = @cell_size * @number_of_columns

		height = window.innerHeight
		width = window.innerWidth

		width = Math.floor height * 0.8
		height -= width

		@canvas.height = width
		@canvas.width = width

		@cell_size = width / @number_of_rows
		@number_of_columns = @number_of_rows

	create_drawing_context: ->
		@drawing_context = @canvas.getContext '2d'

	init_board: ->
		@board = []

		# Clear the field
		for row in [0...@number_of_rows]
			@board[row] = []

			for column in [0...@number_of_columns]
				seed_cell = @seed row, column
				@board[row][column] = seed_cell


		@board[0][0].player = @player
		@board[0][0].color = @user_color
		@draw_grid()
		@show_controls()
		console.log(@board)
	
		
	seed: (row, column) ->
		rand = Math.floor (Math.random() * 100)
		rand = rand % @color_count

		color: @colors[rand]
		row: row
		column: column
		player: null

	draw_grid: ->
		#console.log @board
		for row in [0...@number_of_rows]
			for column in [0...@number_of_columns]
				@draw_cell @board[row][column]

	draw_cell: (cell) ->
		x = cell.row * @cell_size
		y = cell.column * @cell_size
		fill_style = cell.color

		@drawing_context.strokeStyle = 'rgba(242, 198, 65, 0.1)'
		@drawing_context.strokeRect x, y, @cell_size, @cell_size
		@drawing_context.fillStyle = fill_style
		@drawing_context.fillRect x, y, @cell_size, @cell_size

	# Attach the user choice menu.
	show_controls: ->
		new_html = ''
		len = @colors.length
		
		control = document.createElement 'ul'
		control.id = 'controls'
		control.style.cssText = "margin: 0px auto;width:-webkit-fit-content;width:-moz-fit-content;width:fit-content;"

		for i in [0...len]
			new_html = "<li class='color' id='"+i+"' style='background-color:" + @colors[i] + ";color:" + @colors[i] + ";'></li>"
			new_html += ''
			
			control.innerHTML += new_html

		document.body.appendChild control

		width = if window.innerWidth < window.innerHeight then window.innerWidth else window.innerHeight
		width = width / 5

		for child in control.children
			child.style.width = width + 'px'
			child.style.height = width + 'px'
			child.addEventListener 'click', attach_to_child , false


	attach_to_child = () ->
		window.gamex.next this.id

	# Flood fill using user input.
	next: (color) ->
		#console.log 'color = ' + color

		if @is_game_over() != true
			@recalc_field color
			@steps++

	recalc_field: (color) ->
		color = @colors[color]
		for row in [0...@number_of_rows]
			for column in [0...@number_of_columns]
				color_field = @field_is_color(color, row, column)
				neighbour_player = @player_has_neighbour_field(row, column)
				#console.log 'Color = ' + (color_field ? 'true' : 'false') + ' Neighbour = ' + (neighbour_player ? 'true' : 'false') + ' row = ' + row + ' column = ' + column + ' color = ' + color

				if color_field and neighbour_player
					#console.log 'Taking possession : row = ' + row + ' column = ' + column + ' color = ' + color
					@take_possession_of color, row, column

		@update_colors color
		#@draw_grid()

	field_is_color: (color, row, column) ->
		#console.log 'Field is color : color = ' + color + ' row = ' + row + ' column = ' + column
		return (@board[row][column].color == color)

	is_game_over: ->
		return (@board_percentage == 100)

	player_has_neighbour_field: (row, column) ->
		if column > 0 and @board[row][column - 1].player == @player
			return true
		
		if column < @board[row].length - 1 and @board[row][column + 1].player == @player
			return true

		if row > 0 and @board[row - 1][column].player == @player
			return true

		if row < @board.length - 1 and @board[row + 1][column].player == @player
			return true

		return false

	
	take_possession_of: (color, row, column) ->
		#console.log 'Take Possession : row = ' + row + ' column = ' + column
		@board[row][column].player = @player
		@board[row][column].color = color

		if column > 0 and @field_is_color(color, row, column - 1) and @board[row][column - 1].player != @player
			@take_possession_of color, row, column - 1

		if column < @board[row].length - 1 and @field_is_color(color, row, column + 1) and @board[row][column + 1].player != @player
			@take_possession_of color, row, column + 1

		if row > 0 and @field_is_color(color, row - 1, column) and @board[row - 1][column].player != @player
			@take_possession_of color, row - 1, column

		if row < @board.length - 1 and @field_is_color(color, row + 1, column) and @board[row + 1][column].player != @player
			@take_possession_of color, row + 1, column


	update_colors: (color) ->
		total_rects = @number_of_rows * @number_of_columns
		player_rects = 0

		for row in [0...@number_of_rows]
			for column in [0...@number_of_columns]
				if @board[row][column].player == @player
					#console.log 'Update board : row = ' + row + ' column = ' + column
					@board[row][column].color = @user_color
					@draw_cell @board[row][column]
					player_rects++

		
		if player_rects == total_rects
			@board_percentage = 100
		else
			@board_percentage = Math.floor 100 * (player_rects / total_rects)


window.bcolor = bcolor
