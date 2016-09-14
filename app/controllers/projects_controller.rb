class ProjectsController < ApplicationController
	def create
		@project = Project.new
	end
	
	def makeproject
		begin
			user = view_context.get_session_user
			@project = Project.new(params[:project].permit(:title, :description, :time_required, :status))
			if user.is_admin?
				@project.approved = true
			end
			@project.owner = user
			@project.save
			@project.reload
			Member.create(:user_id => user.id, :project_id => @project.id)
		rescue Exception => e
			puts e.inspect
			redirect_to "/projects/create", :notice => "Something went wrong :("
		else
			if user.is_admin?
				redirect_to "/projects/show", :notice => "Created!"
			else
				redirect_to "/projects/show", :notice => "Submitted successfully, pending approval by an admin :)"
			end
		end
	end
	
	def unapproved
		@projects_unapproved = Project.where(:approved => false)
		@volunteers = Volunteer.all
	end
	
	def approve
		begin
			user = view_context.get_session_user
			last = params["last"] ? params["last"] : "show"
			if user and user.is_admin?
				project = Project.find(params[:id])
				project.approved = true
				project.save
				redirect_to "/projects/#{last}", :notice => "Approved."
			end
		rescue Exception => e
			puts e.inspect
		end
		redirect_to "/projects/#{last}", :notice => "Approval failed :("
	end
	
	def my
		# Show a non-admin's projects.
		begin
			user = view_context.get_session_user
			@projects = Project.where(:owner => user)
		rescue Exception => e
			puts e.inspect
		else
		end
	end
	
	def destroyproject
		begin
			user = view_context.get_session_user
			project = Project.find(params[:id])
			last = params["last"] ? params["last"] : "show"
			if user and (user.is_admin? or (project.owner == user and !project.approved))
				project.delete
				redirect_to "/projects/#{last}", :notice => "Deleted."
			else
				redirect_to "/projects/#{last}", :notice => "Delete failed :("	
			end
		rescue Exception => e
			puts e.inspect
		end
		redirect_to "/projects/#{last}", :notice => "Delete failed :("
	end
	
	def show
		if !params[:id]
			projects_unsorted = Project.where(:approved => true)
			projects_double_arr = projects_unsorted.collect {|p| [p.likers.size, p]}
			projects_double_arr.sort!.reverse!
			@projects = projects_double_arr.collect {|el| el[1]}
		else
			@project = Project.find_by_id(params[:id])
			flash[:project_id] = params[:id]
		end
	end
	
	def archive
		# Something can be completed only after it is approved
		projects_unsorted = Project.where(:completed => true)
		projects_double_arr = projects_unsorted.collect {|p| [p.likers.size, p]}
		projects_double_arr.sort!.reverse!
		@projects = projects_double_arr.collect {|el| el[1]}
	end
end
