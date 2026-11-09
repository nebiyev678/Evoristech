-- =================================================================
-- İki sütunu JSON massivinə yığan funksiya (Oracle 19c)
-- Parametr yoxdur, nəticə CLOB kimi qayıdır
-- =================================================================

create or replace function get_options_json return clob is
  vOptionArray json_array_t  := json_array_t();   -- bir dəfə, döngədən əvvəl
  vOption_obj  json_object_t;                     -- döngənin içində yaradılır
begin
  for r in (select item_id, item_name
              from inventory_items
             order by item_name) loop

    vOption_obj := json_object_t();               -- HƏR DÖVRƏDƏ YENİ OBYEKT
    vOption_obj.put('id',   r.item_id);
    vOption_obj.put('name', r.item_name);

    vOptionArray.append(vOption_obj);
  end loop;

  return vOptionArray.to_clob;                    -- CLOB kimi qaytarılır
end;
/


-- ---------- Yoxlama ----------
-- set serveroutput on
-- begin
--   dbms_output.put_line(get_options_json);
-- end;
-- /
--
-- Gözlənilən nəticə:
-- [{"id":1,"name":"Galvanized Pipe Fitting"},{"id":2,"name":"Industrial Caster Wheel"}]
