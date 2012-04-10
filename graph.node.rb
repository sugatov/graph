class Node < TkcArc
	def initialize canvas,id,x,y
		@nodeID = id
		@x = x
		@y = y
		@ways = Hash.new
		super canvas, x-NRAD,y-NRAD, x+NRAD,y+NRAD, 'extent'=>359, 'style'=>'chord', 'width'=>1, 'fill'=>ColorNodeNew,'outline'=>'white'
		@lbl = TkcText.new(canvas,x,y,'text'=>id.to_s,'fill'=>ColorNodeLabel)
	end

	def move(x,y)
		@x = x
		@y = y
		fill ColorNodeNew
		coords x-NRAD,y-NRAD, x+NRAD,y+NRAD
		@lbl.coords x,y
	end

	def fix
		fill ColorNodeFix
	end

	def hit?(x,y,precision)
		if precision**2 >= (@x-x)**2+(@y-y)**2
			true
		else
			false
		end
	end

	def delete
		@lbl.delete
		super
	end



	def to_s
		re = "#{@nodeID} -> "
		@ways.each{|k,n| re += "#{k.to_s},"}
		return re
	end



	attr_reader :nodeID, :x, :y
	attr_accessor :ways
end
