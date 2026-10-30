namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Batata quente: a carta dá a categoria ("marcas de cerveja") e a batata começa
/// com o {jogador} da carta. Quem está com ela fala uma coisa da categoria e toca
/// em "Falei!": a batata passa para o próximo da fila. Ninguém sabe quando o pavio
/// acaba; quando estoura, quem está com a batata leva ponto. Ninguém joga o celular.
/// </summary>
public sealed partial class Sala
{
    /// <summary>De quanto a quanto tempo o pavio pode durar, sorteado a cada carta.</summary>
    internal (int Minimo, int Maximo) SegundosDoPavio { get; set; } = (20, 45);

    private DateTimeOffset AcenderOPavio() =>
        _relogio.GetUtcNow().AddSeconds(_sorteio.Next(SegundosDoPavio.Minimo, SegundosDoPavio.Maximo + 1));

    public void PassarABatata(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Carta) return;
            var rodada = Rodada!;
            if (rodada.Carta.Modo != ModoDeJogo.BatataQuente)
                throw new AcaoNaoPermitidaException("Só vale na Batata quente.");
            // Tocou depois do estouro: tarde demais, a batata estourou na mão.
            if (EstourarSePassouDaHora())
            {
                Tocar();
                return;
            }
            if (jogador.Id != rodada.ComABatata)
                throw new AcaoNaoPermitidaException(
                    $"A batata está com {_jogadores.FirstOrDefault(j => j.Id == rodada.ComABatata)?.Nome ?? "outra pessoa"}.");
            rodada.ComABatata = ProximoComABatata(rodada, jogador.Id);
            Tocar();
        }
    }

    /// <summary>O próximo da fila, dando a volta e pulando quem caiu ou saiu.</summary>
    private Guid ProximoComABatata(Rodada rodada, Guid atual)
    {
        var posicao = Math.Max(0, rodada.Fila.ToList().IndexOf(atual));
        for (var passo = 1; passo < rodada.Fila.Count; passo++)
        {
            var id = rodada.Fila[(posicao + passo) % rodada.Fila.Count];
            if (_jogadores.FirstOrDefault(j => j.Id == id) is { } proximo && Conectado(proximo)) return id;
        }
        return atual;
    }

    /// <summary>
    /// Chamado a cada segundo pelo servidor (e a cada consulta dos celulares).
    /// Verdadeiro quando a batata acabou de estourar e a turma precisa saber.
    /// </summary>
    public bool ConferirBatata()
    {
        lock (_trinco)
        {
            if (!EstourarSePassouDaHora()) return false;
            Tocar();
            return true;
        }
    }

    private bool EstourarSePassouDaHora()
    {
        if (Fase != FaseDaSala.Carta || Rodada is not { Carta.Modo: ModoDeJogo.BatataQuente, EstouraEm: { } quando } ||
            _relogio.GetUtcNow() < quando)
            return false;
        AplicarRevelacao();
        return true;
    }
}
