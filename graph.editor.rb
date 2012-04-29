# encoding: utf-8
$KCODE='UTF-8'

ColorBackground = '#333333'
ColorNodeNew = 'black'
ColorNodeFix = '#777777'
ColorNodeRouted = '#3C93BD' #B0CC54
ColorNodeLabel = 'white'
ColorConnNew = 'white'
ColorConnFix = '#B0CC54'
ColorConnRouted = 'orange' #E16C5B #3C93BD
ColorStatusInactive = '#555555'

NRAD = 12 #радиус вершин

CollisionDetection = true #влияет на производительность
ConnectionBeautify = true #влияет на производительность

HelpString = 'ЛКМ - добавить/переместить вершину, ДВАЖДЫ - удалить. ПКМ - соединение, Control-ПКМ - двустороннее. S - сохранить, L - загрузить.'



require 'tk'
require 'graph.node.rb'
require 'graph.connector.rb'



class GraphEditor < TkCanvas
	def initialize parent, dataModel, width, height
		parent.background = ColorBackground
		@dm = dataModel
		@nodes = @dm.nodes
		@connections = @dm.connections
		@width = width
		@height = height
		@hintPos = (@width/2).round

		super parent,'width'=>width,'height'=>height,'background'=>ColorBackground
		pack
		TkcText.new self,@hintPos,8,'text'=>HelpString,'fill'=>ColorNodeLabel

		@x1 = @y1 = 0

		bind '3', proc{|e| connector(e.x,e.y)}
		bind 'Control-3', proc{|e| connector_double(e.x,e.y)}
		bind 'B3-Motion', proc{|x,y| connector_move(x,y)}, '%x %y'
		bind 'ButtonRelease-3', proc{|x,y| connector_fix(x,y)}, '%x %y'

		bind '1', proc{|e| node(e.x,e.y)}
		bind 'Double-1', proc{|x,y| node_delete(x,y)}, '%x %y'
		bind 'B1-Motion', proc{|x,y| node_move(x,y)}, '%x %y'
		bind 'ButtonRelease-1', proc{|x,y| node_fix(x,y)}, '%x %y'
	end

	def hint str
		TkcText.new self, @hintPos,24, 'text'=>str,'fill'=>ColorNodeLabel
	end

	def status str, color=ColorNodeLabel
		if @statusbar
			@statusbar.text = str
			@statusbar.fill = color
		else
			t = @height - 10
			@statusbar = TkcText.new self, @hintPos,t, 'text'=>str,'fill'=>color
		end
	end

	def node(x,y)
		find = false

		@nodes.each do |key,n|
			if n.hit?(x,y,NRAD)
				find = true
				@node = n
				break
			end
		end
		if not find
			@node = Node.new(self,@dm.nextNode,x,y)
			@dm.addNode @node
		end
	end


	def find_connectors node
		result = Array.new
		id = node.nodeID
		@nodes.each do |i,n|
			str_id = id.to_s+'->'+i.to_s
			if @connections[str_id]
				result.push @connections[str_id]
			end
			str_id = i.to_s+'->'+id.to_s
			if @connections[str_id]
				result.push @connections[str_id]
			end
		end
		return result
	end

	def move_finded list, node, x,y
		list.each do |c|
			x1,x2,y1,y2 = 0
			if c.source == node
				x1=x
				y1=y
				x2=c.dest.x
				y2=c.dest.y
			else
				x1=c.source.x
				y1=c.source.y
				x2=x
				y2=y
			end
			c.move x1,y1, x2,y2
		end
	end

	def fix_finded list, node, x,y
		list.each do |c|
			x1,x2,y1,y2 = 0
			if c.source == node
				x1=x
				y1=y
				x2=c.dest.x
				y2=c.dest.y
			else
				x1=c.source.x
				y1=c.source.y
				x2=x
				y2=y
			end
			c.fix x1,y1, x2,y2
			#puts "Fix: #{c.source.nodeID.to_s}->#{c.dest.nodeID.to_s} : #{c.weight}"
		end
	end

	def node_move(x,y)
		if not @findedconns
			@findedconns = find_connectors @node
		end
		if not CollisionDetection
			@node.move x,y
			move_finded @findedconns, @node, x,y
		else
			find = false
			catch :find do
				@nodes.each do |key,val|
					if key!=@node.nodeID and val.hit?(x,y,NRAD*2)
						find = true
						throw :find
					end
				end
			end
			if not find
				@node.move x,y
				move_finded @findedconns, @node, @node.x,@node.y
			end
		end
	end

	def node_fix(x,y)
		@node.fix
		if @findedconns
			fix_finded @findedconns, @node, @node.x,@node.y
			@findedconns = nil
		end
	end

	def node_delete(x,y)
		catch :find do
			@nodes.each do |key,n|
				if n.hit?(x,y,NRAD)
					@dm.deleteNode key
					throw :find
				end
			end
		end
	end


	
	def connector x,y
		@x1 = x
		@y1 = y
		@line = Connector.new self,x,y, x,y
	end
	def connector_double x,y
		@double = true
		@x1 = x
		@y1 = y
		@line = Connector.new self,x,y, x,y
	end

	def connector_move(x,y)
		if @line
			@line.move @x1,@y1, x,y
		end
	end

	def connector_fix(x,y)
		if @line
			hit1 = hit2 = false
			x1 = @x1
			y1 = @y1
			x2 = x
			y2 = y

			@nodes.each do |key,n|
				if n.hit? x1,y1,NRAD
					hit1=n
					x1=n.x
					y1=n.y
				end
				if n.hit? x2,y2,NRAD
					hit2=n
					x2=n.x
					y2=n.y
				end
			end

			if hit1==false or hit2==false or hit1==hit2
				@line.delete
			else
				@line.move x1,y1, x2,y2
				id = hit1.nodeID.to_s+'->'+hit2.nodeID.to_s
				if @connections[id]
					@line.delete
				else
					@line.source = hit1
					@line.dest = hit2
					@line.fix x1,y1, x2,y2
					hit1.ways[hit2.nodeID]=hit2
					@connections[id] = @line

					id = hit2.nodeID.to_s+'->'+hit1.nodeID.to_s
					if @double and not @connections[id]
						line2 = Connector.new self, x2,y2, x1,y1
						line2.source = hit2
						line2.dest = hit1
						line2.fix x2,y2, x1,y1
						hit2.ways[hit1.nodeID]=hit1
						@connections[id]=line2
					end
					@double = false
					#puts 'Connection: '+id+' weight:'+@line.weight.to_s
				end
			end
		end
	end


end