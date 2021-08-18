# Start guard
# guard --guardfile Guardfile.rb

guard :shell do
	# Compile changes to source
	watch(%r{^(bin)/format-ops.rb$}) { |m| 
	UI.info "Make-ing an fm"
	`ruby #{m[1]}/#{m[2]} #{ENV{PINHOME}/include/bw_ops.h` 
	}
end

guard :shell do
	# Restart CM when an so changes
	watch(%r{^(lib)/.*\.so$}){ |m|
		UI.info "Restarting b/c #{m[1]}"
		restart_cm()
	}
end

# Restart CM when an fm changes
#guard Lib
#end


def restart_cm
	`pinps reload cm`
	#`stop_cm;sleep 5;toggle-colorstart_cm;sleep 1`
end
