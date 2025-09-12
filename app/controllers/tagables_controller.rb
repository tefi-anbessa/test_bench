class TagablesController < ApplicationController
  def new
    @tag = Tag.find(tagable_params[:tag_id])
    case tagable_params[:tagable_type]
    when "Demand"
      redirect_to new_tag_demand_path(@tag)
    when "Cable"
      redirect_to new_tag_cable_path(@tag)
    else 
      flash[:danger] = "Tag type #{tagable_params[:tagable_type]} is not implemented"
      redirect_back_or_to @tag
    end
  end

  private

  def tagable_params
    params.require(:tag_id).permit(:tagable_type)
  end
end
