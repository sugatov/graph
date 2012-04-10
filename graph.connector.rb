class Connector < TkcLine
	def initialize canvas,x1,y1,x2,y2
		@x1 = x1
		@y1 = y1
		@x2 = x2
		@y2 = y2
		@source = nil
		@dest = nil
		super canvas, x1,y1, x2,y2, 'arrow'=>'last','width'=>1,'fill'=>ColorConnNew
	end

	def move x1,y1, x2,y2
		@x1 = x1
		@x2 = x2
		@y1 = y1
		@y2 = y2
		
		if @fixed
			fix2
		else
			coords x1,y1, x2,y2
		end
	end

	def fix x1,y1, x2,y2
		move x1,y1, x2,y2
		a = (x1-x2)**2.abs
		b = (y1-y2)**2.abs
		c = Math.sqrt(a+b)
		@weight = c
		fill ColorConnFix

		fix2
	end


	def fix2 #устранение наложения бёдер на вершины
		if not ConnectionBeautify
			return
		end
		if @source.hit? @dest.x,@dest.y,NRAD*4
			@FRAD = NRAD/3
		else
			@FRAD = NRAD
		end
		
		x0=x1=y0=y1=0

		dx = @source.x - @dest.x
		dy = @source.y - @dest.y

		if dx.abs > dy.abs
			if @source.x < @dest.x
				x0 = @source.x
				y0 = @source.y
				x1 = @dest.x
				y1 = @dest.y
				p1 = ily @source, @source.x, @source.x+@FRAD+1, x0,y0,x1,y1
				p2 = ily @dest, @dest.x, @dest.x-@FRAD-1, x0,y0,x1,y1
				coords p1.x,p1.y, p2.x,p2.y
				
			else
				x1 = @source.x
				y1 = @source.y
				x0 = @dest.x
				y0 = @dest.y
				p1 = ily @dest, @dest.x, @dest.x+@FRAD+1, x0,y0,x1,y1
				p2 = ily @source, @source.x, @source.x-@FRAD-1, x0,y0,x1,y1
				coords p2.x,p2.y, p1.x,p1.y
			end
			
		else
			if @source.y < @dest.y
				x0 = @source.x
				y0 = @source.y
				x1 = @dest.x
				y1 = @dest.y
				p1 = ilx @source, @source.y, @source.y+@FRAD+1, x0,y0,x1,y1
				p2 = ilx @dest, @dest.y, @dest.y-@FRAD-1, x0,y0,x1,y1
				coords p1.x,p1.y, p2.x,p2.y
			else
				x1 = @source.x
				y1 = @source.y
				x0 = @dest.x
				y0 = @dest.y
				p1 = ilx @dest, @dest.y, @dest.y+@FRAD+1, x0,y0,x1,y1
				p2 = ilx @source, @source.y, @source.y-@FRAD-1, x0,y0,x1,y1
				coords p2.x,p2.y, p1.x,p1.y
			end
		end

		@fixed = true
	end


	def lx y, x0,y0, x1,y1 #получить x через y по уравнению прямой
		if not @lx_angle		
			x0 = Float(x0)
			x1 = Float(x1)
			y0 = Float(y0)
			y1 = Float(y1)
			@lx_angle = (x1-x0)/(y1-y0)
		end

		x = @lx_angle * (y-y0) + x0

		return Integer(x)
	end

	def ly x, x0,y0, x1,y1 #получить y через x по уравнению прямой
		if not @ly_angle
			x0 = Float(x0)
			y0 = Float(y0)
			x1 = Float(x1)
			y1 = Float(y1)
			@ly_angle = (y1-y0)/(x1-x0)
		end

		y = @ly_angle * (x-x0) + y0

		return Integer(y)
	end

	def ily obj, x,e, x0,y0, x1,y1 #поиск непересекающейся точки итерацией по x
		@ly_angle = nil
		while x!=e
			if e>x
				x+=1
			else
				x-=1
			end
			y = ly x, x0,y0, x1,y1
			if not obj.hit? x,y,@FRAD
				return Point.new x,y
			end
		end
	end
	
	def ilx obj, y,e, x0,y0, x1,y1 #поиск непересекающейся точки итерацией по y
		@lx_angle = nil
		while y!=e
			if e>y
				y+=1
			else
				y-=1
			end
			x = lx y, x0,y0, x1,y1
			if not obj.hit? x,y,@FRAD
				return Point.new x,y
			end
		end
	end


	def to_s
		return "#{@source.nodeID}->#{@dest.nodeID}: \t#{@weight}"
	end


	attr_reader :weight
	attr_accessor :source, :dest
end


class Point
	def initialize x,y
		@x = x
		@y = y
	end

	attr_accessor :x, :y
end