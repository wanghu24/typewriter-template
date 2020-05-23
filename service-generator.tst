${
    using Typewriter.Extensions.WebApi;
    using System.Text.RegularExpressions;
    using System.Diagnostics;

    string ToKebabCase(string typeName){
        return  Regex.Replace(typeName, "(?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z])","-$1", RegexOptions.Compiled)
                     .Trim().ToLower();
    }

    string CleanupUrl(string url)
    {
        var result = (url ?? "").Split('?', '#')[0].Replace("/${id}","");
        return result;
    }
    string CleanupName(string propertyName, bool? removeArray = true){
        if (removeArray.HasValue && removeArray.Value) {
            propertyName = propertyName.Replace("[]","");
        }
        return propertyName.Replace("Controller", "Service");
    }

    string ImportProperties(Class c)
    {
        List<Type> types = new List<Type>();

        foreach(var ps in c.Methods.Select(q=> q.Parameters)){
          types.AddRange(ps.Select(q=> q.Type).Where(t => !t.IsPrimitive || t.IsEnum)
            .Select(t => t.IsGeneric ? t.TypeArguments.First() : t)
            .Where(t => t.Name != c.Name && t.Name != "DbGeography"));
        }

        return string.Join(Environment.NewLine, types.Distinct().Select(t => $"import {{ {t.Name} }} from '../models/{GenerateFileName(t.Name)}';").Distinct());
    }

    string GenerateFileName(string className){
        className = CleanupName(className);
        className = ToKebabCase(className);
        return className;
    }

    string GenerateMethod(Method method) {
      var result = "";

      if(method.Parameters!=null&& method.Parameters.Any()){
        
      }

      if(method.HttpMethod() != "post" && method.HttpMethod() != "put" && method.Parameters != null) {
      result +=  Environment.NewLine;
      result += "    const params = new HttpParams()";

      foreach(var p in method.Parameters) {
        result += ".set('" + p.name + "', ";

        if(p.Type == "string")
          result += p.name + ")";
        else
          result += p.name + ".toString())";
      }

      result += ";";
      }

      result +=  Environment.NewLine;
      result += "    return this.http." + method.HttpMethod() + "<" + ReturnType(method) + ">(this.api + '" + CleanupUrl(method.Url()) + "'";

       

      if(method.HttpMethod() == "post" || method.HttpMethod() == "put") {
        result += ", " + method.Parameters.First().name;
      }
      else {
        result += ", { params }";
      }

      result += ");"; 
      return result;
    }
    string ReturnType(Method m) => m.Type.Name == "IHttpActionResult" ? "void" : m.Type.Name;
    string ServiceName(Class c) => c.Name.Replace("Controller", "Service");
    string ApiName(Class c) => c.name.Replace("Controller", "");

    Template(Settings settings)
    {
        settings
            .IncludeCurrentProject()
            .IncludeProject("TypeWriterTest");

        //settings.OutputExtension = ".tsx";

        settings.OutputFilenameFactory = (file) => {
            if (file.Classes.Any()){
                var className = GenerateFileName(file.Classes.First().Name);
                return $"services\\{className}.ts";
            }
            return file.Name;
        };
    }
}
$Classes(TypeWriterTest.Controllers.*)[
import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { environment } from 'src/environments/environment';
$ImportProperties

@Injectable({
  providedIn: 'root'
})

export class $ServiceName {
  api = environment.apiUrl;

  constructor(private http: HttpClient) { }

$Methods[
  $name($Parameters[$name: $Type][, ]): Observable<$ReturnType> {$GenerateMethod
  }
]
}

