
#ifndef DAGMC_PROGRESSBAR_H
#define DAGMC_PROGRESSBAR_H

class ProgressBar {

 public:
  // constructor
  ProgressBar() { 
    // initialize bar
    set_value(0.0);
  };

  // destructor
  ~ProgressBar()  {
    if (need_final_newline) {
      std::cout << std::endl;
    }
  };

  void set_value(double val);

  static bool is_terminal();

 private:
  int current {0};
  bool need_final_newline {false};
};

#endif // HEADER GUARD
