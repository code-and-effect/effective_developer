<% if namespaced? -%>
require_dependency '<%= namespaced_path %>/application_controller'

<% end -%>
<% module_namespacing do -%>
class <%= namespaced_class_name %>Controller < <%= [namespace_path.classify, ApplicationController].join('::') %>
  before_action :authenticate_user! # Devise enforce user is present

<% if actions.delete('index') -%>
  def index
    @page_title = '<%= plural_name.titleize %>'
    authorize! :index, <%= class_name %>

    @datatable = Effective::Datatables::<%= namespaced_class_name %>.new(params[:scopes])
  end

<% end -%>
<% if actions.delete('new') -%>
  def new
    @<%= singular_name %> = <%= class_name %>.new

    @page_title = 'New <%= human_name %>'
    authorize! :new, @<%= singular_name %>
  end

<% end -%>
<% if actions.delete('create') -%>
  def create
    @<%= singular_name %> = <%= class_name %>.new(permitted_params)

    @page_title = 'New <%= human_name %>'
    authorize! :create, @<%= singular_name %>

    if @<%= singular_name %>.save
      flash[:success] = 'Successfully created <%= singular_name %>'
      redirect_to(redirect_path)
    else
      flash.now[:danger] = "Unable to create <%= singular_name %>: #{@<%= singular_name %>.errors.full_messages.to_sentence}"
      render :new
    end
  end

<% end -%>
<% if actions.delete('show') -%>
  def show
    @<%= singular_name %> = <%= class_name %>.find(params[:id])

    @page_title = @<%= singular_name %>.to_s
    authorize! :show, @<%= singular_name %>
  end

<% end -%>
<% if actions.delete('edit') -%>
  def edit
    @<%= singular_name %> = <%= class_name %>.find(params[:id])

    @page_title = "Edit #{@<%= singular_name %>}"
    authorize! :edit, @<%= singular_name %>
  end

<% end -%>
<% if actions.delete('update') -%>
  def update
    @<%= singular_name %> = <%= class_name %>.find(params[:id])

    @page_title = "Edit #{@<%= singular_name %>}"
    authorize! :update, @<%= singular_name %>

    if @<%= singular_name %>.update_attributes(permitted_params)
      flash[:success] = 'Successfully updated <%= singular_name %>'
      redirect_to(redirect_path)
    else
      flash.now[:danger] = "Unable to update <%= singular_name %>: #{@<%= singular_name %>.errors.full_messages.to_sentence}"
      render :edit
    end
  end

<% end -%>
<% if actions.delete('destroy') -%>
  def destroy
    @<%= singular_name %> = <%= class_name %>.find(params[:id])
    authorize! :destroy, @<%= singular_name %>

    if @<%= singular_name %>.destroy
      flash[:success] = 'Successfully deleted <%= singular_name %>'
    else
      flash.now[:danger] = "Unable to delete <%= singular_name %>: #{@<%= singular_name %>.errors.full_messages.to_sentence}"
    end

    redirect_to <%= index_path %>
  end

<% end -%>
<% if actions.delete('unarchive') -%>
  def unarchive
    @<%= singular_name %> = <%= class_name %>.find(params[:id])
    authorize! :unarchive, @<%= singular_name %>

    if @<%= singular_name %>.unarchive
      flash[:success] = 'Successfully restored <%= singular_name %>'
    else
      flash.now[:danger] = "Unable to restore <%= singular_name %>: #{@<%= singular_name %>.errors.full_messages.to_sentence}"
    end

    redirect_to <%= index_path %>
  end

<% end -%>
<% actions.each do |action| -%>
  def <%= action %>
    @<%= singular_name %> = <%= class_name %>.find(params[:id])

    @page_title = "<%= action.titleize %> #{@<%= singular_name %>}"
    authorize! :<%= action %>, @<%= singular_name %>
  end

<% end -%>
  private

  def permitted_params
    params.require(:<%= singular_name %>).permit(:id,
<% attributes_names.each_slice(8).with_index do |slice, index| -%>
      <%= slice.map { |name| permitted_param_for(name) }.join(', ') %><%= ',' if ((index+1) * 8) < attributes.length %>
<% end -%>
    )
  end

  def redirect_path
    case params[:commit].to_s
    when 'Save'
      <%= edit_path %>
    when 'Save and Continue'
      <%= index_path %>
    when 'Save and Add New'
      <%= new_path %>
    else
      raise 'Unexpected redirect path'
    end
  end

end
<% end -%>
