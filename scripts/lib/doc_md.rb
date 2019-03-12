require 'sequel'
require 'nokogiri'
require 'rubytree'

class MarkdownDocument

  PROPERTY_COLUMNS = ['Name','Data Type','Cardinality','Notes']

  CARDINALITY_LABELS = {
    '0..1' => 'Zero or One',
    '1' => 'Exactly One',
    '0..n' => 'Zero or More',
    '1..n' => 'One or More'
  }

  INDENT_SIZE = 2

  def initialize(path,header,footer,root_property)
    @path = path
    @header = header
    @footer = footer
    @content = ''
    @root_property = root_property
    @root_node = build_tree(@root_property)
  end

  def generate
    @content += generate_html_tree(@root_node)
    @content += "\n<hr/>\n\n"
    @content += "## All Properties\n\n"
    @content += generate_table(@root_node.children)
    @content += "\n<hr/>\n\n"
  end

  def generate_nested_li(node)
    li = ('  '*node.node_depth)
    li += "* [#{node.name}](##{node.name})\n"
    return li
  end

  def generate_html_tree(node)
    html_tree = ''
    node.print_tree(node.node_depth,nil,lambda { |node, prefix| html_tree += "#{generate_nested_li(node)}" })
    return html_tree
  end

  def generate_table(node_array)
    table_content = "<table><thead><tr>"
    PROPERTY_COLUMNS.each {|col| table_content += "<th>#{col}</th>"}
    table_content += "</tr></thead>"
    table_content += "<tbody>"
    node_array.each do |node|
      table_content += "#{get_node_as_html_table_row(node)}\n"
    end
    table_content += "</tbody></table>"
    return get_formatted_html(table_content)
  end

  def get_formatted_html(raw_html)
    doc = Nokogiri::XML::DocumentFragment.parse(raw_html)
    return doc.to_xml(indent:INDENT_SIZE)
  end


  def build_tree(root_property)
    root_node = Tree::TreeNode.new("DMP", {})
    root_node = add_node_to_parent(root_node,root_property)
    return root_node
  end

  def add_node_to_parent(parent_node,parent_property)
    parent_property.children.each do |property|
      new_node = Tree::TreeNode.new(property.label_machine,get_property_attributes_as_hash(property))
      new_node.content['depth'] = new_node.node_depth
      parent_node << new_node
      if(!property.children.empty?) then
        property.children.each do |child_property|
          add_node_to_parent(new_node,child_property)
        end
      end
    end
    return parent_node
  end

  def get_property_attributes_as_hash(property)
    {
      :data_type => property.data_type.label,
      :cardinality => CARDINALITY_LABELS[property.cardinality],
      :notes => property.notes
    }
  end

  def get_node_as_html_table_row(node)
    html = "<tr><td><span id=\"#{node.name}\">#{node.name}</span></td>"
    html += "<td>#{process_content_for_table_cell(node.content[:data_type])}</td>"
    html += "<td>#{process_content_for_table_cell(node.content[:cardinality])}</td>"
    html += "<td>#{process_content_for_table_cell(node.content[:notes])}</td>"
    html += "</tr>"
    return html
  end

  def process_content_for_table_cell(content)
    if(content == nil || content == '') then
      return ' '
    else
      return content
    end
  end


  def write_to_file
    File.open(@path,'w') do |f|
      f.write @header
      f.write @content
      f.write @footer
    end
  end
end

