using System.Collections.Concurrent;
using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Api.Infraestrutura;

/// <summary>
/// As salas vivem só durante a noite de jogo: ficam na memória e somem
/// depois de horas paradas. Um novo deploy também encerra as salas abertas.
/// </summary>
public sealed class SalasEmMemoria(Baralho baralho, TimeProvider? relogio = null)
{
    // Sem I e O, que se confundem com 1 e 0 quando alguém dita o código.
    private const string Letras = "ABCDEFGHJKLMNPQRSTUVWXYZ";
    internal const int TamanhoDoCodigo = 4;
    internal static readonly TimeSpan TempoParada = TimeSpan.FromHours(12);

    private readonly ConcurrentDictionary<string, Sala> _salas = new(StringComparer.OrdinalIgnoreCase);
    private readonly TimeProvider _relogio = relogio ?? TimeProvider.System;

    public Sala Criar()
    {
        LimparParadas();
        while (true)
        {
            var codigo = string.Concat(Enumerable.Range(0, TamanhoDoCodigo)
                .Select(_ => Letras[Random.Shared.Next(Letras.Length)]));
            var sala = new Sala(codigo, baralho, relogio: _relogio);
            if (_salas.TryAdd(codigo, sala)) return sala;
        }
    }

    public Sala Obter(string codigo) =>
        _salas.TryGetValue(codigo.Trim(), out var sala) ? sala : throw new SalaNaoEncontradaException();

    public void DescartarSeVazia(Sala sala)
    {
        if (sala.Vazia) _salas.TryRemove(sala.Codigo, out _);
    }

    internal void LimparParadas()
    {
        var limite = _relogio.GetUtcNow() - TempoParada;
        foreach (var (codigo, sala) in _salas)
            if (sala.UltimaAtividade < limite)
                _salas.TryRemove(codigo, out _);
    }
}
