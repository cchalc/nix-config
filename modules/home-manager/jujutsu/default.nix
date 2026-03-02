{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Christopher Chalcraft";
        email = "chris.chalcraft@gmail.com";
      };
      git = {
        "write-change-id-header" = true;
      };
      "--scope" = [
        {
          "--when" = {
            repositories = ["~/work"];
          };
          user.email = "christopher.chalcraft@databricks.com";
        }
      ];
    };
  };
}