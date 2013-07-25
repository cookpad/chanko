class EntriesController < ApplicationController
  unit_action :entry_deletion, :destroy

  def index
    invoke(:entry_deletion, :index) do
      @entries = Entry.all
    end
  end

  def show
    @entry = Entry.find(params[:id])
  end

  def new
    @entry = Entry.new
    render :edit
  end

  def create
    @entry = Entry.create(params[:entry].permit(:title, :body))
    redirect_to @entry
  end

  def edit
    @entry = Entry.find(params[:id])
  end

  def update
    @entry = Entry.find(params[:id])
    @entry.update_attributes(params[:entry].permit(:title, :body))
    redirect_to @entry
  end
end
