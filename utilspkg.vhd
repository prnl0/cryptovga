package utils_pkg is
  function digit_to_char(dig : natural range 0 to 9) return character;
  function nat_to_str(
    num     : natural;
    max_len : natural
  ) return string;
end package utils_pkg;

package body utils_pkg is
  function digit_to_char(dig : natural range 0 to 9) return character is
  begin
    case dig is
      when 0 => return '0';
      when 1 => return '1';
      when 2 => return '2';
      when 3 => return '3';
      when 4 => return '4';
      when 5 => return '5';
      when 6 => return '6';
      when 7 => return '7';
      when 8 => return '8';
      when 9 => return '9';
    end case;
  end function digit_to_char;
  
  function nat_to_str(
    num     : natural;
    max_len : natural
  ) return string is
    variable ret : string(1 to max_len) := (others => '0');
    variable rec : natural := 0;
    variable dig : natural := max_len;
  begin
    if (num <= 9) then
      ret(max_len) := digit_to_char(num);
      return ret;
    end if;
    rec := num;
    while rec > 0 and dig > 0 loop
      ret(dig) := digit_to_char(rec mod 10);
      rec := rec / 10;
      dig := dig - 1;
    end loop;
    return ret;
  end function nat_to_str;
end package body utils_pkg;