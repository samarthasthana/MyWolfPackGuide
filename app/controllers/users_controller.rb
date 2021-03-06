require 'rubygems'
#require 'google_calendar'
require 'gcal4ruby'


class UsersController < ApplicationController

  before_action :require_login, :except => [:login, :new]
  before_action :login_check, :only => [:login]

  private

  def login_check
    puts "Coming to login check"
  end

  def require_login
    puts "Goes into require_login"
    if (session[:uid].nil?)
      puts "was nil"
      flash[:error]="Not authenticated to view resource"
      redirect_to '/'
    else
      puts "was not null"
      return true
    end

  end

  public

  def logout
    session[:uid]=nil
    # dump all the data  
    flash[:notice]="Successfully Logged out"
    redirect_to '/'
  end

  def login
    redirect_path=nil
    if request.post?
      # check if the user id is ncsu email id
      # check userid blank # check pwd blank
      if (params[:user]=="" || params[:password]=="")
        flash[:error]="Username or password cannot be blank"
        redirect_path= '/'
      else
        #authenticate the uid and pwd
        # check if the user exists
        @user_entry=User.find_by_user_name(params[:user])
        puts(@user_entry.nil?)
        if (@user_entry.nil?)
          flash[:error]="User was not found"
          redirect_path= '/'
        else
          # check if the password hash match
          if (@user_entry.password!=params[:password])
            flash[:error]="Incorrect password"
            redirect_path= '/'
          end
        end
      end
      if (!redirect_path.nil?)
        redirect_to redirect_path
      else
        # redirect to home_page with session [:name]
        if (@user_entry.user_type=="A")
          #redirect to admin home page
          session[:uid]=@user_entry.id
          redirect_to '/admin_home'
        else
          session[:uid]=@user_entry.id
          session[:user_name]=@user_entry.user_name
          redirect_to '/home_page'
        end
      end
    end
  end

  def new
    if request.post?
      redirect_path=nil
      # check if any of the fields are empty
      if (params[:new_user_name]=="" || params[:new_user_password]=="" || params[:new_user_confirm]=="" || params[:new_user_email]=="")
        flash[:error]="A required field was left empty"
        redirect_path='/users/new'
      else
        # check if the user already exists
        @user_check=User.find_by_user_name(params[:new_user_name])
        @user_check2=User.find_by_email(params[:new_user_email])
        if (!@user_check.nil? || !@user_check2.nil?)
          flash[:error]="User with this username or email id already exists in the system"
          redirect_path= '/users/new'
        else
          # check if password and confirm password match
          if (params[:new_user_password]!=params[:new_user_confirm])
            flash[:error]="Password and confirm password do not match"
            redirect_path= '/users/new'
          else
            # check if the email id is an ncsu email id
            exp=/\A[\w+\-.]+@ncsu.edu\z/i
            if ((params[:new_user_email]=~exp).nil?)
              flash[:error]="Email id is not of NCSU domain"
              redirect_path= '/users/new'
            end
          end
        end
      end

      if (redirect_path.nil?)
        # register the new user and persist
        @user_new=User.new
        @user_new.user_name=params[:new_user_name]
        @user_new.password=params[:new_user_password]
        @user_new.user_type="N"
        @user_new.email=params[:new_user_email]
        @user_new.department=params[:all_val]
        @user_new.user_interest=params[:user_interest]
        if (@user_new.save!)
          flash[:notice]="User successfully registered"
        else
          flash[:error]="Something went wrong, registration failed"
        end
        redirect_to '/'
      else
        redirect_to redirect_path
      end
    end
  end

  def edituser
    @User_edit=User.find(session[:uid])

  end

  def updateuser
    @use=User.find(params[:id])
    @use.user_name=params[:name]
    @use.password=params[:password]
    @use.department=params[:all_val]
    @use.user_interest=params[:user_interest]
    @use.save
    if (@use.save!)
      flash[:notice]="User succesfully edited"
    else
      flash[:error]="Something went wrong"
    end
    redirect_to '/home_page'

  end


  def home_page
    usr = User.find(session[:uid])
    department = usr.department
    interests = usr.user_interest
    catids = Array.new
    catids << department.to_i
    if !interests.nil?
      catids.concat(interests)
    end
    calids = Calendar.where("category_id in (?)",catids)
    @calid = calids.map(&:Calid)

=begin
    @calid = Array.new
    @calid << "http://www.google.com/calendar/feeds/ncsu.edu_hpasl5cmtenq7biv0omve1nvq8@group.calendar.google.com/public/basic"
    @calid << "https://www.google.com/calendar/feeds/ncsu.edu_olma5do53nidmtbjtc9d7l0ue0%40group.calendar.google.com/public/basic"
=end

    service = GCal4Ruby::Service.new
    service.authenticate("the.wolfpackguide@gmail.com", "admin2wolfpack")
    session[:service]=service

  end

  def admin_home
    #@cat=Category.find(params[:id])
    @cal=Calendar.all
    @cat=Category.all
  end


end
