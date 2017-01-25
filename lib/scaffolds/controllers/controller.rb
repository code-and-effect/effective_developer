class <%= resource.namespaced_class_name.pluralize %>Controller < <%= [resource.namespace.try(:classify).presence, ApplicationController].compact.join('::') %>
  before_action :authenticate_user! # Devise enforce user is present

<% if defined?(EffectiveResources) -%>
  include Effective::CrudController

<% end -%>
<% if actions.delete('index') && !defined?(EffectiveResources) -%>
  def index
    @page_title = '<%= resource.plural_name.titleize %>'
    authorize! :index, <%= resource.class_name %>

    @datatable = <%= resource.namespaced_class_name.pluralize %>Datatable.new(params[:scopes])
  end

<% end -%>
<% if actions.delete('new') && !defined?(EffectiveResources) -%>
  def new
    @<%= resource.name %> = <%= resource.class_name %>.new

    @page_title = 'New <%= resource.human_name %>'
    authorize! :new, @<%= resource.name %>
  end

<% end -%>
<% if actions.delete('create') && !defined?(EffectiveResources) -%>
  def create
    @<%= resource.name %> = <%= resource.class_name %>.new(<%= resource.name %>_params)

    @page_title = 'New <%= resource.human_name %>'
    authorize! :create, @<%= resource.name %>

    if @<%= resource.name %>.save
      flash[:success] = 'Successfully created <%= resource.name %>'
      redirect_to(redirect_path)
    else
      flash.now[:danger] = "Unable to create <%= resource.name %>: #{@<%= resource.name %>.errors.full_messages.to_sentence}"
      render :new
    end
  end

<% end -%>
<% if actions.delete('show') && !defined?(EffectiveResources) -%>
  def show
    @<%= resource.name %> = <%= resource.class_name %>.find(params[:id])

    @page_title = @<%= resource.name %>.to_s
    authorize! :show, @<%= resource.name %>
  end

<% end -%>
<% if actions.delete('edit') && !defined?(EffectiveResources) -%>
  def edit
    @<%= resource.name %> = <%= resource.class_name %>.find(params[:id])

    @page_title = "Edit #{@<%= resource.name %>}"
    authorize! :edit, @<%= resource.name %>
  end

<% end -%>
<% if actions.delete('update') && !defined?(EffectiveResources) -%>
  def update
    @<%= resource.name %> = <%= resource.class_name %>.find(params[:id])

    @page_title = "Edit #{@<%= resource.name %>}"
    authorize! :update, @<%= resource.name %>

    if @<%= resource.name %>.update_attributes(<%= resource.name %>_params)
      flash[:success] = 'Successfully updated <%= resource.name %>'
      redirect_to(redirect_path)
    else
      flash.now[:danger] = "Unable to update <%= resource.name %>: #{@<%= resource.name %>.errors.full_messages.to_sentence}"
      render :edit
    end
  end

<% end -%>
<% if actions.delete('destroy') && !defined?(EffectiveResources) -%>
  def destroy
    @<%= resource.name %> = <%= resource.class_name %>.find(params[:id])
    authorize! :destroy, @<%= resource.name %>

    if @<%= resource.name %>.destroy
      flash[:success] = 'Successfully deleted <%= resource.name %>'
    else
      flash[:danger] = "Unable to delete <%= resource.name %>: #{@<%= resource.name %>.errors.full_messages.to_sentence}"
    end

    redirect_to <%= resource.index_path %>
  end

<% end -%>
<% if actions.delete('unarchive') -%>
  def unarchive
    @<%= resource.name %> = <%= resource.class_name %>.find(params[:id])
    authorize! :unarchive, @<%= resource.name %>

    if @<%= resource.name %>.unarchive
      flash[:success] = 'Successfully restored <%= resource.name %>'
    else
      flash.now[:danger] = "Unable to restore <%= resource.name %>: #{@<%= resource.name %>.errors.full_messages.to_sentence}"
    end

    redirect_to <%= resource.index_path %>
  end

<% end -%>
<% actions.each do |action| -%>
  def <%= action %>
    @<%= resource.name %> = <%= resource.class_name %>.find(params[:id])

    @page_title = "<%= action.titleize %> #{@<%= resource.name %>}"
    authorize! :<%= action %>, @<%= resource.name %>
  end

<% end -%>
  protected

  def <%= resource.name %>_params
    params.require(:<%= resource.name %>).permit(:id,
<% attributes.each_slice(8).with_index do |slice, index| -%>
      <%= slice.map { |att| permitted_param_for(att.name) }.join(', ') %><%= ',' if (((index+1) * 8) < attributes.length || resource.nested_resources.present?) %>
<% end -%>
<% resource.nested_resources.each_with_index do |(_, nested_resource), index| -%>
      <%= nested_resource.name %>_attributes: [:id, :_destroy, <%= (nested_resource.belong_tos_attributes + nested_resource.attributes).map { |att| ':' + att.name.to_s }.join(', ') %>]<%= ',' if index < resource.nested_resources.length-1 %>
<% end -%>
    )
  end

<% if !defined?(EffectiveResources) -%>
  def redirect_path
    case params[:commit].to_s
    when 'Save'
      <%= resource.edit_path_helper %>
    when 'Save and Continue'
      <%= resource.index_path %>
    when 'Save and Add New'
      <%= resource.new_path %>
    else
      raise 'Unexpected redirect path'
    end
  end

<% end -%>
end
