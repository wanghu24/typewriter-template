${  using Typewriter.Extensions.Types;
    using System.Text.RegularExpressions;
    using System.Diagnostics;

    string ToKebabCase(string typeName){
        return  Regex.Replace(typeName, "(?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z])","-$1", RegexOptions.Compiled)
                     .Trim().ToLower();
    }

    string CleanupName(string propertyName, bool? removeArray = true){
        if (removeArray.HasValue && removeArray.Value) {
            propertyName = propertyName.Replace("[]","");
        }
        return propertyName.Replace("Model","");
    }

    string GenerateFileName(string className){
        className = CleanupName(className);
        className = ToKebabCase(className);
        return className;
    }

    string Nullable(Property property) => property.Type.IsNullable ? $"?" : $"";

    string ImportProperties(Class c)
    {
        IEnumerable<Type> types = c.Properties
            .Select(p => p.Type)
            .Where(t => !t.IsPrimitive || t.IsEnum)
            .Select(t => t.IsGeneric ? t.TypeArguments.First() : t)
            .Where(t => t.Name != c.Name && t.Name != "DbGeography")
            .Distinct();
        return string.Join(Environment.NewLine, types.Select(t => $"import {{ {t.Name} }} from './{GenerateFileName(t.Name)}';").Distinct());
    }

    string ImportsBaseClass(Class c)
    {
        List<string> neededImports = new List<string>();

        if (c.BaseClass != null)
        {
            neededImports.Add("import { " + c.BaseClass.Name + " } from './" + c.BaseClass.Name + "';");
        }

        return String.Join(Environment.NewLine, neededImports.Distinct()); 
    }

    string ClassNameWithExtends(Class c) => c.Name + (c.BaseClass != null ? " extends " + c.BaseClass.Name : "");

    string PropertyDefaultValue(Property p)
    {

        
        if(p.Type.IsEnum)
        return "0";

        if(p.Type.IsNullable)
        return "null";

        if(p.Type.Name == "string")
        return "''";

        if(p.Type.Name == "number")
        return "0";

        return p.Type.Default();
    }

    Template(Settings settings)
    {
        settings
            .IncludeCurrentProject()
            .IncludeProject("TypeWriterTest");

        //settings.OutputExtension = ".tsx";

        settings.OutputFilenameFactory = (file) => {
            if (file.Classes.Any()){
                var className = GenerateFileName(file.Classes.First().Name);
                return $"models\\{className}.ts";
            }
            if (file.Enums.Any()){
                var className = GenerateFileName(file.Enums.First().Name);
                return $"models\\{className}.ts";
            }
            return file.Name;
        };
    }
}$Classes(TypeWriterTest.Models.*)[$ImportsBaseClass
$ImportProperties
export class $ClassNameWithExtends {
$Properties[
    $name$Nullable: $Type;]

    constructor() {$Properties[
        this.$name = $PropertyDefaultValue;]
    }
}]$Enums(TypeWriterTest.Models.*)[export enum $Name {$Values[
    $Name = $Value][,]
}]

