var app = angular.module('mongolab', ['ngResource', '$strap.directives']).
    factory('Project', function($resource) {
      var Project = $resource('https://api.mongolab.com/api/1/databases/super-client-db/collections/projects/:id',
          { apiKey: 'xejrnWMgW1XnXj-2wn1rU4SGAEVJLh1V' }, {
            update: { method: 'PUT' }
          }
      );
        
      Project.prototype.update = function(cb) {
        return Project.update({id: this._id.$oid},
            angular.extend({}, this, {_id:undefined}), cb);
      };
 
      Project.prototype.destroy = function(cb) {
        return Project.remove({id: this._id.$oid}, cb);
      };

 
      return Project;
    });

app.factory('DataSource', ['$http',function($http){
       return {
           get: function(file,callback,transform){
                $http.get(
                    '/guitars.xml',
                    {transformResponse:transform}
                ).
                success(function(data, status) {
                    console.log("Request succeeded");
                    callback(data);
                }).
                error(function(data, status) {
                    console.log("Request failed " + status);
                });
           }
       };
}]);

app.directive('cselect', function() {
    console.log('call custom select directive');
    return {
        restrict: 'E', 
        templateUrl: 'custom-select.html',
        link: function postLink(scope, iElement, iAttrs) { 
          console.log('postlink');
          scope.$watch(iAttrs.ngModel, function(){
            
          });

        }
    }  
});

function loadPrettySelect(){
  console.log('load it up!');
  $('.selectpicker').selectpicker({style: 'btn-info'}); 
}

function ListCtrl($scope, Project, DataSource) {
  //loadPrettySelect();
  $scope.projects = Project.query();

  var SOURCE_FILE = "guitars.xml";
    
    $scope.IMAGE_LOCATION = "http://rabidgadfly.com/assets/angular/xmlload/";
    
    xmlTransform = function(data) {
        console.log("transform data");
        var x2js = new X2JS();
        var json = x2js.xml_str2json( data );
        return json.guitars.guitar;
    };
    
    setData = function(data) {
        $scope.dataSet = data;
    };

    DataSource.get(SOURCE_FILE,setData,xmlTransform);

}

function CreateCtrl($scope, $location, Project) {
  $scope.save = function() {
    Project.save($scope.project, function(project) {
      $location.path('/edit/' + project._id.$oid);
    });
  }
}
 
 
function EditCtrl($scope, $location, $routeParams, Project) {
  var self = this;
 
  Project.get({id: $routeParams.projectId}, function(project) {
    self.original = project;
    $scope.project = new Project(self.original);
  });
 
  $scope.isClean = function() {
    return angular.equals(self.original, $scope.project);
  }
 
  $scope.destroy = function() {
    self.original.destroy(function() {
      $location.path('/list');
    });
  };
 
  $scope.save = function() {
    $scope.project.update(function() {
      $location.path('/');
    });
  };
}

