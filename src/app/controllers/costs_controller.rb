#
#   copyright 2012 red hat, inc.
#
#   licensed under the apache license, version 2.0 (the "license");
#   you may not use this file except in compliance with the license.
#   you may obtain a copy of the license at
#
#       http://www.apache.org/licenses/license-2.0
#
#   unless required by applicable law or agreed to in writing, software
#   distributed under the license is distributed on an "as is" basis,
#   without warranties or conditions of any kind, either express or implied.
#   see the license for the specific language governing permissions and
#   limitations under the license.
#

class CostsController < ApplicationController
  before_filter :require_user

  def edit_billing
    unless @hardware_profile
      @hardware_profile = HardwareProfile.find(params[:id])
    end
    require_privilege(Privilege::MODIFY, @hardware_profile)

    unless @hardware_profile.provider_hardware_profile?
      flash[:warning] = t "hardware_profiles.flash.warning.cannot_assign_cost_to_frontend_hwp"
      redirect_to hardware_profile_path(@hardware_profile)
      return
    end

    @hwp_cost = @hardware_profile.cost_now || Cost.new
    @title = @hardware_profile.name.titlecase
  end

  def edit
    unless @hardware_profile
      @hardware_profile = HardwareProfile.find(params[:id])
    end
    require_privilege(Privilege::MODIFY, @hardware_profile)

    unless @hardware_profile.provider_hardware_profile?
      flash[:warning] = t "hardware_profiles.flash.warning.cannot_assign_cost_to_frontend_hwp"
      redirect_to hardware_profile_path(@hardware_profile)
      return
    end

    @hwp_cost = @hardware_profile.cost_now || Cost.new
    @hwp_prop_costs = {}
    HardwareProfile::chargeables.each { |what| 
      @hwp_prop_costs[what] = @hardware_profile.send(what).cost_now || Cost.new
    }

    @header  = [
      { :name => t('hardware_profiles.properties_headers.name'), 
        :sort_attr => :name},
      { :name => t('hardware_profiles.properties_headers.billing_model'),
        :sort_attr => :billing_model},
      { :name => t('hardware_profiles.properties_headers.cost'),
        :sort_attr => :cost}]
    @title = @hardware_profile.name.titlecase
  end

  def update_billing
    unless params[:id]
      redirect_to hardware_profiles_path
    end

    @hardware_profile = HardwareProfile.find(params[:id])
    require_privilege(Privilege::MODIFY, @hardware_profile)

    # terminate profile cost that exists atm
    @hardware_profile.close_costs(false)

    begin
      # set hardware profile cost
      Cost.create!( 
        :chargeable_id   => @hardware_profile.id,
        :chargeable_type => CostEngine::CHARGEABLE_TYPES[:hardware_profile],
        :price           => 0,
        :valid_from      => Time.now(),
        :valid_to        => nil,
        :billing_model   => params[:cost][:billing_model]
      )

      flash[:notice] = t"hardware_profiles.flash.notice.cost_updated"
      redirect_to edit_cost_path(@hardware_profile)
    rescue
      render :action => 'edit_cost' # FIXME: id?
    end
  end

  def update
    unless params[:id]
      redirect_to hardware_profiles_path
    end

    @hardware_profile = HardwareProfile.find(params[:id])
    require_privilege(Privilege::MODIFY, @hardware_profile)

    # terminate costs that exist atm
    @hardware_profile.close_costs

    #begin
      # set hardware profile cost
      #cost_now = @hardware_profile.cost_now
      Cost.create!( 
        :chargeable_id   => @hardware_profile.id,
        :chargeable_type => CostEngine::CHARGEABLE_TYPES[:hardware_profile],
        :price           => (params[:cost][:price] rescue 0),
        :valid_from      => Time.now(),
        :valid_to        => nil,
        :billing_model   => billing_model = params[:cost][:billing_model]
      )
      
      if billing_model == 'per_property'
        # set hardware profile properties costs
        HardwareProfile::chargeables.each do |type|
          billing_model_param_name = type.to_s+'_billing_model'
          Cost.create!(
            :chargeable_id   => @hardware_profile.send((type.to_s+'_id').intern),
            :chargeable_type => CostEngine::CHARGEABLE_TYPES[('hw_'+type.to_s).intern],
            :price           => params[type.to_s+'_cost'],
            :valid_from      => Time.now(),
            :valid_to        => nil,
            :billing_model   => params[billing_model_param_name]
          ) unless params[billing_model_param_name] == 'none'
        end
      end

      flash[:notice] = t"hardware_profiles.flash.notice.cost_updated"
      redirect_to hardware_profile_path(@hardware_profile)
    #rescue
    #  render :action => 'edit_cost' # FIXME: id?
    #end
  end
end
