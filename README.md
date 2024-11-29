### Why this project ?
This repository serves as a comprehensive template for creating Infrastructure as Code (IaC) projects using Terraform and Terragrunt. Designed with scalability, maintainability, and the principle of DRY (Don't Repeat Yourself) in mind, it empowers users to build robust infrastructure solutions efficiently. This project is strategically structured to achieve the following capabilities:

* **Keep your Terraform code DRY**: Instead of adding repeated configurations such as providers or project-level values, this template helps you declare these globally or once within the project and reuse them everywhere.
* **Keep your remote State configurations DRY**: Having a huge Terraform state that represents your entire infrastructure can be tricky, especially when there is some part of the state that is corrupted, resulting in the entire state becoming unusable. The solution for this is to have a backend (remote state) configuration in each of the submodules that create a remote state. This template helps implement this in a non-repetitive way.
* **Keep your terragrunt architecture DRY**: Keeping configurations like the above globally and inheriting these in the child modules can be tricky. Using this template helps you tackle this problem in such a way that child modules can inherit these from the root of the project.

### What's Included?
* **Custom scripts**: Custom logics are embedded in this template to implement the capabilities such as DRY code , DRY state backend configurations and DRY architecture.
* **Strategic project structure**: Project is structured in such a way that you can get all of the above capabilities with minimal changes.

### Simple and maintainable Folder structure

Typically in a project, we have to manage infrastructure resources using different modules and all these resources configured for different environments. Keeping them in a structured way can be beneficial in terms of reuse and maintainability. You can structure your Terraform code in the below way with help of Terragrunt.
Here's a simplified example:

```
|----staging 
|    |--- ec2 
|    |    |--- instance 
|    |    |    |--- main.tf 
|    |    |    |--- outputs.tf 
|    |    |    |--- variables.tf 
|    |    |--- ec2.yaml 
|    |    |--- terragrunt.hcl 
|    |--- rds 
|    |    |--- instance 
|    |    |    |--- main.tf 
|    |    |    |--- outputs.tf 
|    |    |    |--- variables.tf 
|    |    |--- rds.yaml 
|    |    |--- terragrunt.hcl 
|    |--- eks 
|    |	 |--- terragrunt.hcl 
|    |   |--- eks.yaml 
|----prod 
|    |--- ec2 
|    |    |--- instance 
|    |    |    |--- main.tf 
|    |    |    |--- outputs.tf 
|    |    |    |--- variables.tf 
|    |    |--- ec2.yaml 
|    |    |--- terragrunt.hcl 
|    |--- rds 
|    |    |--- instance 
|    |    |    |--- main.tf 
|    |    |    |--- outputs.tf 
|    |    |    |--- variables.tf 
|    |    |--- rds.yaml 
|    |    |--- terragrunt.hcl 
|    |--- eks 
|    |	 |--- terragrunt.hcl 
|    |   |--- eks.yaml 
|----common.yaml 
|----empty.yaml 
|----terragrunt.hcl 
```

Now, let’s have a look at this folder structure.
This folder structure contains

* parent folder named staging and prod (represents the environment for which you want to create the resources in )
* inside, folders named ec2 and rds (represents the resources you want to create) and each contains
* a local terraform module with code necessary to create the resources
* a <child_folder_name>.yaml
* a terragrunt.hcl
* folder named eks which refers to a remote module in the terragrunt.hcl and uses eks.yaml as value file
* a common.yaml file which we will use to hold some values common to all the services
* a root terragrunt.hcl for common hcl scripts

By adopting this structure, you can centralize and manage shared configurations efficiently. Terragrunt simplifies the deployment and maintenance of multiple modules across different environments, promoting code reuse and minimizing duplication.

This repository offers a structured template for enhancing the maintainability of Infrastructure as Code (IaC) using Terraform.

Alongside this repository, you'll find an in-depth [blog post](https://example.com) that explores the rationale behind this methodology, highlights its benefits, and offers practical guidance for its application.



### Decoding var_inputs: The Secret Sauce in Our Terragrunt Recipe 

Prior to reading this section, we recommend taking a walkthrough of the above mentioned blog to gain a full understanding of this repository and how it functions.

Let’s dissect the local variables defined in the root terragrunt.hcl that contribute to the creation of var_inputs. 
 
 ````
default_yaml = find_in_parent_folders("empty.yaml") 
````

 
The *default_yaml* variable holds the content of an empty YAML file, serving as a fallback if a specific file is not found. (Hold tight, things will become clearer in the next step.) 
 
 ````
common_var_file_path = "${find_in_parent_folders("common.yaml", local.default_yaml)}" 
 ````
*common.yaml* houses variables common to our entire project. If it can’t be located, this variable defaults to the path of the empty YAML. 
 
 ```
current_module_file_path = "${get_terragrunt_dir()}" 
 ```
When child Terragrunt modules include this file, *current_module_file_path* represents the module’s path. 
 
 ```
application_name = basename(local.current_module_file_path) 
 ```
Utilizing the basename function, an inbuilt Terraform function, this variable retains only the last portion of the filesystem path. For instance, it transforms "foo/bar/baz.txt" into "baz.txt". 
eg : 
 ```
> basename("foo/bar/baz.txt") 
baz.txt 
 ```

 ```
 environment_name = basename(dirname(dirname(local.current_module_file_path))) 
 ```

By using the *dirname* function, another Terraform built-in function, it removes the last portion from a filesystem path. Since we apply it twice, if the *child_module_path* is something like *"dev/remote-state/remote-state.yaml"* , you’ll get *"dev"* as the output, representing the environment name. 
 
```
common_environment_var_file_path = "${find_in_parent_folders("${local.environment_name}.yaml", local.default_yaml)}" 
```
This variable proves handy if you plan to organize Terraform configs for all environments in a single project, separating them by directory names (though not recommended for large projects). Essentially, it allows you to have a dev.yaml file (or environment_name.yaml) to store environment-specific variables. 
 
 ```
application_specific_var_file_path = "${get_terragrunt_dir()}/${local.application_name}.yaml" 
```
Refers to the YAML files kept in the child Terraform modules to override their parent’s settings (covered in detail above). 
 
 ```
common_inputs                     = yamldecode(file(local.common_var_file_path)) 
common_environment_inputs         = yamldecode(file(local.common_environment_var_file_path)) 
application_environment_inputs    = yamldecode(file(local.application_specific_var_file_path)) 
 
combined_app_settings = merge(merge(local.common_app_settings, local.common_environment_app_settings),local.application_environment_settings) 
```
In this step, we intersect all defined variables and assign precedence. The variables defined at the root level YAML, those in the environment-level directories, and those in the child Terraform modules are all merged. Variables in the inner YAMLs take priority over those defined at the outer level. If a variable isn’t defined, the one from the outer level is used. 
 
```
common_app_settings                     = lookup(local.common_inputs, "app_settings", {})  
common_environment_app_settings         = lookup(local.common_environment_inputs, "app_settings", {}) 
application_environment_settings        = lookup(local.application_environment_inputs, "app_settings",{}) 
 
combined_app_settings = merge(merge(local.common_app_settings, local.common_environment_app_settings),local.application_environment_settings) 
```
This is another necessary step since *app_settings* is a map. It doesn’t merge as part of the generic file merge, only replaces, so manual merging is required. 
 
 ```
var_inputs = merge(local.combined_inputs, {app_settings = local.combined_app_settings } ) 
```
Finally, we merge the combined *app settings* and *inputs* together, giving precedence to *combined_app_settings*. 
 
And finally this variable will be available in the child modules since child modules includes this config and also it is given as inputs in the root *terragrunt.hcl* . 
 
 
 ### Getting Started:
 
To begin using this repository, simply clone it to your local machine and follow the instructions provided in the documentation. You'll be up and running with a robust infrastructure project in no time!

### References

**Terraform Tips: Simple Strategies for Smarter Infrastructure** - [blog](https://example.com)

**Terragrunt**: [official terragrunt documentation](https://terragrunt.gruntwork.io/docs/getting-started/quick-start/)