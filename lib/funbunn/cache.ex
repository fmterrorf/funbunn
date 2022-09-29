defmodule Funbunn.Cache do
  @cache :funbunn_cache

  def get(key) do
    ConCache.get(@cache, key)
  end

  def insert(key, value) do
    ConCache.insert_new(@cache, key, value)
  end
end
