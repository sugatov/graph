################################################################################
# License: 		MIT
# Author: 		Eugene Sugatov
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


class Node < TkcArc

	attr_reader :nodeID, :x, :y
	attr_accessor :ways, :lbl


	def text
		@lbl.text
	end
	def text=val
		@lbl.text = val
	end
	def text val,color=ColorNodeLabel
		@lbl.text = val
		@lbl.fill color
	end


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


end
