# encoding: utf-8
$KCODE='UTF-8'

################################################################################
# License: 		MIT
# Author: 		Eugene Sugatov
# Latest version available at: https://github.com/sugatov/graph/
#
# Copyright (C) 2012, Eugene Sugatov
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
# THE SOFTWARE.
################################################################################


#параметры:

ColorScheme1 = Hash[
	'Background'		=>'#333333',
	'NodeNew'			=>'#000000',
	'NodeFix'			=>'#777777',
	'NodeRouted'		=>'#5B3C91',
	'NodeLabel'			=>'#FFFFFF',
	'NodeLabel2'		=>'#000000',
	'ConnNew'			=>'#FFFFFF',
	'ConnFix'			=>'#B0CC54',
	'ConnRouted'		=>'#E21D1D',
	'Status'			=>'#FFFFFF',
	'StatusInactive'	=>'#555555',
	'StatusErr'			=>'#D85F05',
	'Grid'				=>'#555555'
]
ColorScheme2 = Hash[
	'Background'		=>'#FFFFFF',
	'NodeNew'			=>'#000000',
	'NodeFix'			=>'#282828',
	'NodeRouted'		=>'#C0C0C0',
	'NodeLabel'			=>'#FFFFFF',
	'NodeLabel2'		=>'#969696',
	'ConnNew'			=>'#000000',
	'ConnFix'			=>'#000080',
	'ConnRouted'		=>'#0066FF',
	'Status'			=>'#000000',
	'StatusInactive'	=>'#808080',
	'StatusErr'			=>'#FF0000',
	'Grid'				=>'#7D7DAA'
]


NRAD = 12 #радиус вершин

CollisionDetection = true #влияет на производительность, без первичной аппроксимации
ConnectionBeautify = true #влияет на производительность




HelpString = 'M1 - доб./перем. вершину, DBL M1 - удалить. M2 - соединение, Control-M2 - двустороннее. M3 - функц.кнопки.'



require 'tk'
require 'graph.node.rb'
require 'graph.connector.rb'
require 'graph.model.rb'



class GraphEditor < TkCanvas

	attr_reader		:cs

	def initialize parent, dataModel, width=900, height=540
		@cs = ColorScheme1
		@locked = false

		parent.background = @cs['Background']
		@dm = dataModel
		@nodes = @dm.nodes
		@connections = @dm.connections
		@width = width
		@height = height
		@hintPos = (@width/2).round

		@btnPos = Point.new 8+12,24+12
		

		super parent,'width'=>width,'height'=>height,'background'=>@cs['Background']
		pack
		@hint1 = TkcText.new self,@hintPos,8,'text'=>HelpString,'fill'=>@cs['Status']
		toggleGrid

		@x1 = @y1 = 0

		focus

		bind '3', proc{|e| connector(e.x,e.y)}
		bind 'Control-3', proc{|e| connector_double(e.x,e.y)}
		bind 'B3-Motion', proc{|x,y| connector_move(x,y)}, '%x %y'
		bind 'ButtonRelease-3', proc{|x,y| connector_fix(x,y)}, '%x %y'

		bind '1', proc{|e| node(e.x,e.y)}
		bind 'Double-1', proc{|x,y| node_delete(x,y)}, '%x %y'
		bind 'B1-Motion', proc{|x,y| node_move(x,y)}, '%x %y'
		bind 'ButtonRelease-1', proc{|x,y| node_fix(x,y)}, '%x %y'

		bind 'n', proc{normalize}
		bind 'q', proc{reset}
		#bind 'i', proc{puts "~~~~ Nodes & Ribs:\r\n#{@dm}--------"}
		bind 'm', proc{loadImage}
		bind 'g', proc{toggleGrid}


		b1 = imgButton 'btn.new.gif', 'Сброс (Q)'
		b1.bind '2', proc{reset}
		b2 = imgButton 'btn.grid.gif', 'Сетка (G)'
		b2.bind '2', proc{toggleGrid}
		b3 = imgButton 'btn.img.gif', 'Загрузить фоновое изображение (M)'
		b3.bind '2', proc{loadImage}

	end

	def reset
		if locked? then puts '~~~~ Reset is impossible, i`m busy.'; return end
		@connections.each {|k,c| c.delete}
		@nodes.each {|k,n| n.delete}
		@dm.reset
		if @displayImg then @displayImg.delete end
		unlock
	end

	def hint str
		@hint2 = TkcText.new self, @hintPos,24, 'text'=>str,'fill'=>@cs['Status']
	end

	def status str, color=@cs['Status']
		if @statusThr and @statusThr.alive?
			@statusThr.kill
		end
		@statusThr = Thread.new {
			if @statusbar
				@statusbar.text = str
				@statusbar.fill = color
			else
				t = @height - 16
				@statusbar = TkcText.new self, @hintPos,t, 'text'=>str,'fill'=>color, 'font'=>TkFont.new('Verdana 10 bold')
			end
			sleep 2
			@statusbar.text = ''
		}
	end

	def drawGrid h, v, color=@cs['Grid']
		@grid = Array.new
		ih = (self.height / (h)).round
		iv = (self.width / (v)).round
		pos = 0
		h -= 1
		h.times do
			pos += ih
			l = TkcLine.new self, 0,pos, self.width,pos, 'width'=>1, 'fill'=>color
			l.lower
			@grid.push l
		end
		pos = 0
		v -= 1
		v.times do
			pos += iv
			l = TkcLine.new self, pos,0, pos,self.height, 'width'=>1, 'fill'=>color
			l.lower
			@grid.push l
		end
		if @displayImg then @displayImg.lower end
	end
	def remGrid
		if @grid
			@grid.each do |g|
				g.delete
			end
			@grid.clear
		end
	end
	def toggleGrid h=12,v=20, color=@cs['Grid']
		if @grid and @grid.count>0
			remGrid
		else
			drawGrid h,v, color
		end
	end

	def switchColorScheme forceMain=false
		if forceMain
			@cs = ColorScheme1
		else
			@cs = @cs==ColorScheme1 ? ColorScheme2 : ColorScheme1
		end
		normalize true,true,true,true
	end
	

	def imgButton file, hint=''
		x = @btnPos.x
		y = @btnPos.y
		b = ImgButton.new self, x,y, file
		b.bind 'Motion', proc{status hint}
		@btnPos.y += 32
		return b
	end


	def loadImage
		if @displayImg
			@displayImg.delete
			switchColorScheme true
		end
		filename = Tk::getOpenFile
		if File.exists? filename
			#require 'tkextlib/tkimg'
			x = (self.width/2).round
			y = (self.height/2).round
			img = TkPhotoImage.new 'file'=>filename
			@displayImg = TkcImage.new self, x,y, 'image'=>img
			@displayImg.lower
			switchColorScheme
		end
	end

	def normalize text = true, nbg = true, cbg = true, grid = false
		@nodes.each do |k,n|
			if text then n.text n.nodeID,@cs['NodeLabel'] end
			if nbg then n.fill @cs['NodeFix'] end
		end
		if cbg
			@connections.each do |k,c|
				c.fill @cs['ConnFix']
			end
		end
		if grid and @grid and @grid.count>0
			@grid.each do |g|
				g.fill @cs['Grid']
			end
		end
		if @hint1 then @hint1.fill @cs['Status'] end
		if @hint2 then @hint2.fill @cs['Status'] end
	end

	def lock
		@locked = true
	end
	def unlock
		@locked = false
	end
	def locked?
		return @locked
	end

	
	def node x,y
		if locked? then return end

		fn = findNode x,y
		if not fn
			@node = Node.new self, @dm.nextNode, x,y
			@dm.addNode @node
		else
			@node = fn
		end
	end

	def findNode x,y
		@nodes.each do |k,n|
			if n.hit? x,y,NRAD
				return n
			end
		end
		return false
	end

	def node_move x,y
		if locked? then return end

		if not @findedconns
			@findedconns = find_conns @node
		end
		if not CollisionDetection
			@node.move x,y
			move_conns @findedconns, @node, x,y
		else
			find = false
			catch :find do
				@nodes.each do |k,n|
					if k!=@node.nodeID and n.hit?(x,y,NRAD*2)
						find = true
						throw :find
					end
				end
			end
			if not find
				@node.move x,y
				move_conns @findedconns, @node, @node.x,@node.y
			end
		end
	end

	def node_fix x,y
		if locked? then return end

		@node.fix
		if @findedconns
			fix_conns @findedconns, @node, @node.x,@node.y
			@findedconns = nil
		end
	end

	def find_conns node
		result = Array.new
		@nodes.each do |k,n|
			id = Array.new [@dm.connectionID(node,n), @dm.connectionID(n,node)]
			id.each do |c|
				if @connections[c] then result.push @connections[c] end
			end
		end
		
		return result
	end
	def move_conns list, node, x,y
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
	def fix_conns list, node, x,y
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
		end
	end

	def node_delete x,y
		if locked? then return end

		catch :find do
			@nodes.each do |k,n|
				if n.hit?(x,y,NRAD)
					@dm.deleteNode k
					throw :find
				end
			end
		end
	end



	def connector x,y
		if locked? then return end

		@x1 = x
		@y1 = y
		@connector = Connector.new self, x,y, x,y
	end
	def connector_double x,y
		if locked? then return end

		@double_c = true
		@x1 = x
		@y1 = y
		@connector = Connector.new self, x,y, x,y
	end

	def connector_move x,y
		if locked? then return end

		if @connector
			@connector.move @x1,@y1, x,y
		end
	end

	def connector_fix x,y
		if locked? then return end

		if @connector
			hit1 = hit2 = false
			x1 = @x1
			y1 = @y1
			x2 = x
			y2 = y

			catch :find do
				@nodes.each do |k,n|
					if n.hit? x1,y1,NRAD
						hit1 = n
						x1 = n.x
						y1 = n.y
					end
					if n.hit? x2,y2,NRAD
						hit2 = n
						x2 = n.x
						y2 = n.y
					end
					if hit1 and hit2
						throw :find
					end
				end
			end

			if not hit1 or not hit2 or hit1 == hit2
				@connector.delete
			else
				#@connector.move x1,y1, x2,y2
				id = @dm.connectionID hit1,hit2
				if @connections[id]
					@connector.delete
				else
					@connector.source = hit1
					@connector.dest = hit2
					@connector.fix x1,y1, x2,y2
					@dm.addConnection @connector
				end

				id = @dm.connectionID hit2,hit1
				if @double_c and not @connections[id]
					conn2 = Connector.new self, x2,y2, x1,y1
					conn2.source = hit2
					conn2.dest = hit1
					conn2.fix x2,y2, x1,y1
					@dm.addConnection conn2
				end
				@double_c = false
			end
		end
	end




end




class ImgButton < TkcImage
	def initialize parent, x,y, filename
		@img = TkPhotoImage.new 'file'=>filename
		super parent, x,y, 'image'=>@img
	end
end