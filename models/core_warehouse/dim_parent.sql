{{
  config(
    post_hook=[
        "alter table {{ this }} add primary key (k_parent)",
    ]
  )
}}

with stg_parent as (
    select * from {{ ref('stg_ef3__parents') }}
),
parent_phones_wide as (
    select * from {{ ref('bld_ef3__parent_wide_phone_numbers') }}
),
parent_emails_wide as (
    select * from {{ ref('bld_ef3__parent_wide_emails') }}
),
choose_address as (
    {{ row_pluck(ref('stg_ef3__parents__addresses'),
                key='k_parent',
                column='address_type',
                preferred='Home',
                where='(do_not_publish is null or not do_not_publish)') }}
),
formatted as (
    select 
        stg_parent.k_parent,
        stg_parent.tenant_code,
        stg_parent.api_year as school_year,
        stg_parent.parent_unique_id,
        stg_parent.person_id,
        stg_parent.login_id,
        stg_parent.person_source_system,
        stg_parent.last_name || ', ' || stg_parent.first_name as display_name,
        stg_parent.first_name,
        stg_parent.last_name,
        stg_parent.middle_name,
        stg_parent.maiden_name,
        stg_parent.personal_title_prefix,
        stg_parent.generation_code_suffix,
        stg_parent.sex,
        stg_parent.highest_completed_level_of_education,
        {{ accordion_columns(
            source_table='bld_ef3__parent_wide_phone_numbers',
            exclude_columns=["k_parent", "tenant_code"],
            source_alias='parent_phones_wide'
        ) }}
        {{ accordion_columns(
            source_table='bld_ef3__parent_wide_emails',
            exclude_columns=["k_parent", "tenant_code"],
            source_alias='parent_emails_wide'
        ) }}
        choose_address.full_address
    from stg_parent
    left join parent_phones_wide
      on stg_parent.k_parent = parent_phones_wide.k_parent
    left join parent_emails_wide
      on stg_parent.k_parent = parent_emails_wide.k_parent
    left join choose_address
        on stg_parent.k_parent = choose_address.k_parent
)
select * from formatted
order by tenant_code, k_parent