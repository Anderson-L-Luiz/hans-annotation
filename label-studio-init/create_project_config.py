"""
Create labelstud.io project configuration
"""

import argparse
import json
import sys
import os

from jinja2 import Template


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--format", default="json", type=str, help="Format of the generated config, one of: 'xml', 'json'")
    parser.add_argument("-p", "--project-name", type=str, help="Name of the snippet project")
    return parser.parse_args()


def dump_json(data) -> str:
    """
     Dump JSON to str
    """
    return json.dumps(data, indent=2, ensure_ascii=False)


def read_json_file(file):
    """
    Read a json file and return json
    """
    with open(file, mode="r", encoding="utf-8") as in_file:
        return json.load(in_file)


def get_project_titles(projects_data):
    """
    Get list of project titles
    """
    titles = []
    for entry in projects_data["projects"]:
        titles.append(str(entry["project"]["title"]))
    return titles


def get_project_config(projects_data, project_name):
    """
    Get project config from project name
    """
    for entry in projects_data["projects"]:
        if entry["project"]["title"] == project_name:
            return entry


def gen_xml_config_from_templates(project_config, template_types_views, templates_data, template_types_data):
    """
    Generate xml config using jinja template engine
    """
    project_view_type = project_config["type"]
    project_members = project_config["members"]
    project_members_count = len(project_members)

    # Load project specific view template
    template = Template(template_types_views[project_view_type]["template"])
    template_members = template_types_views[project_view_type]["members"]
    template_members_count = len(template_members)

    if template_members_count > 0 and project_members_count > 0:
        if project_members_count == template_members_count:
            # Do rendering of template_data using template_types_data
            render_data = {}
            for member in template_members:
                if member["type"] == "list":
                    # template_list contains e.g. question templates to be instanciated
                    template_type_name = member["value"]
                    templates_list = project_members[template_type_name]
                    sub_xml_rendered = []
                    for template_name in templates_list:
                        template_type = templates_data[template_type_name][template_name]["type"]
                        question_template = Template(template_types_data[template_type]["template"])
                        sub_xml_rendered.append(
                          question_template.render(
                            {**templates_data[template_type_name][template_name]["members"]}
                          )
                        )
                    render_data[member["value"]] = sub_xml_rendered
                else:
                    print(f"Project contains unsupported member type: '{project_members}' not valid - Exit")
                    sys.exit()
            return template.render(render_data)
    else:
        return template.render()


def main():
    """
    Create labelstud.io project configuration
    """
    args = parse_args()

    projects_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "projects")
    templates_dir = os.path.join(projects_dir, "templates")

    projects_data = read_json_file(os.path.join(projects_dir, "projects.json"))
    project_titles = get_project_titles(projects_data)

    if args.project_name in project_titles:
        project_name = args.project_name
    else:
        print(f"Provided project name '{args.project_name}' not valid - Exit")
        sys.exit()

    project_config = get_project_config(projects_data, project_name)

    template_types_views = read_json_file(os.path.join(templates_dir, "template-types-views.json"))
    templates_data = read_json_file(os.path.join(templates_dir, "templates.json"))
    template_types_data = read_json_file(os.path.join(templates_dir, "template-types.json"))

    xml_config = gen_xml_config_from_templates(
      project_config, template_types_views, templates_data, template_types_data)

    if args.format == "xml":
        print(xml_config)
    elif args.format == "json":
        project_config["project"]["label_config"] = str(xml_config)
        print(dump_json(project_config["project"]))
    else:
        print(f"Provided format '{args.format}' not valid - Exit")


if __name__ == "__main__":
    main()
