namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>Selfie de reação de quem foi pego numa carta; forma o mural da noite.</summary>
public sealed record Momento(
    string Id, Guid JogadorId, string NomeDoJogador, int Rodada, string Texto, FotoDoJogador Foto);

public sealed partial class Sala
{
    internal const int LimiteDeMomentos = 60;

    private readonly List<Momento> _momentos = [];

    internal IReadOnlyList<Momento> Momentos => _momentos;

    public void RegistrarMomento(string token, int numeroDaRodada, byte[] conteudo)
    {
        var foto = FotoDoJogador.Criar(conteudo);
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Revelada)
                throw new AcaoNaoPermitidaException("A foto do mural é tirada na hora da revelação.");
            if (!Protagonistas(Rodada!).Contains(jogador.Id))
                throw new AcaoNaoPermitidaException("Só quem foi pego nesta carta entra no mural.");

            // Tirou outra: fica a mais nova.
            _momentos.RemoveAll(m => m.Rodada == numeroDaRodada && m.JogadorId == jogador.Id);
            if (_momentos.Count >= LimiteDeMomentos)
                throw new AcaoNaoPermitidaException("O mural da noite já está cheio.");
            _momentos.Add(new Momento(foto.Id, jogador.Id, jogador.Nome, numeroDaRodada, Rodada!.Texto, foto));
            Tocar();
        }
    }

    /// <summary>Quem a carta pegou: bebeu, foi escolhido(a), conta a história, é o réu ou o casal da vez.</summary>
    internal static HashSet<Guid> Protagonistas(Rodada rodada)
    {
        var protagonistas = new HashSet<Guid>(rodada.Revelacao?.Perderam ?? []);
        protagonistas.UnionWith(rodada.Revelacao?.Escolhidos ?? []);
        if (rodada.Revelacao?.ContaAHistoria is { } historia) protagonistas.Add(historia);
        if (rodada.Palpiteiro is { } palpiteiro) protagonistas.Add(palpiteiro);
        if (rodada.Alvo is { } alvo) protagonistas.Add(alvo);
        return protagonistas;
    }
}
