; generated from: oatprograms/lib14.oat
target triple = "x86_64-unknown-linux"
define i64 @program(i64 %_argc2693, { i64, [0 x i8*] }* %_argv2691) {
  %_argc2694 = alloca i64
  %_argv2692 = alloca { i64, [0 x i8*] }*
  %_a2707 = alloca { i64, [0 x i64] }*
  store i64 %_argc2693, i64* %_argc2694
  store { i64, [0 x i8*] }* %_argv2691, { i64, [0 x i8*] }** %_argv2692
  %_raw_array2695 = call i64* @oat_alloc_array(i64 10)
  %_array2696 = bitcast i64* %_raw_array2695 to { i64, [0 x i64] }*
  %_ind2697 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 0
  store i64 126, i64* %_ind2697
  %_ind2698 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 1
  store i64 125, i64* %_ind2698
  %_ind2699 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 2
  store i64 124, i64* %_ind2699
  %_ind2700 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 3
  store i64 123, i64* %_ind2700
  %_ind2701 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 4
  store i64 122, i64* %_ind2701
  %_ind2702 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 5
  store i64 121, i64* %_ind2702
  %_ind2703 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 6
  store i64 120, i64* %_ind2703
  %_ind2704 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 7
  store i64 119, i64* %_ind2704
  %_ind2705 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 8
  store i64 118, i64* %_ind2705
  %_ind2706 = getelementptr { i64, [0 x i64] }, { i64, [0 x i64] }* %_array2696, i32 0, i32 1, i32 9
  store i64 117, i64* %_ind2706
  store { i64, [0 x i64] }* %_array2696, { i64, [0 x i64] }** %_a2707
  %_a2708 = load { i64, [0 x i64] }*, { i64, [0 x i64] }** %_a2707
  %_result2709 = call i8* @string_of_array({ i64, [0 x i64] }* %_a2708)
  call void @print_string(i8* %_result2709)
  ret i64 0
}


declare i64* @oat_alloc_array(i64)
declare { i64, [0 x i64] }* @array_of_string(i8*)
declare i8* @string_of_array({ i64, [0 x i64] }*)
declare i64 @length_of_string(i8*)
declare i8* @string_of_int(i64)
declare i8* @string_cat(i8*, i8*)
declare void @print_string(i8*)
declare void @print_int(i64)
declare void @print_bool(i1)
